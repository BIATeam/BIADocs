---
sidebar_position: 1
---
# Infrastructure data project

## Preparation of the Database

1. Create the database on your local instance
    - The name of the database should be the name of the project — verify the connection string in `bianetconfig.json` and its environment-specific variants
2. Rename and fill in the configuration files in the **DeployDB** project:
    - `appsettings.Example_Development.json` → `appsettings.Development.json`
    - `bianetconfig.Example_Development.json` → `bianetconfig.Development.json`
    - Set `BiaNet.DatabaseConfigurations[0].ConnectionString` and `Provider` to match your local instance (see [Configuration files](#configuration-files) below)
3. *(Only for a new project — no migration exists yet)* Create the first migration using the VS Code task **"Database Add migration SqlServer"** or the equivalent CLI command (see [Creating Migrations](#creating-migrations-ef-cli) below)
4. Apply the migrations to the database by **launching the DeployDB project** — it automatically runs `Migrate()` on startup
5. *(Optionally)* Update the Roles section in `bianetconfig.json` and its environment-specific variants to use the correct AD groups or fake roles
6. *(Optionally)* Update the application version in `[Company].[Project].Crosscutting.Common.Constants.Application.Version`

---

## Configuration Files

The **DeployDB** project is the only project that needs configuration to run migrations. It reads two layered configuration files at startup: `appsettings.json` and `bianetconfig.{env}.json`.

### `bianetconfig.Development.json`

This is the most important file to set up. It controls which database and provider EF Core targets.

```json
{
  "BiaNet": {
    "DatabaseConfigurations": [
      {
        "Key": "ProjectDatabase",
        "Provider": "SQLServer",
        "ConnectionString": "data source=localhost;initial catalog=DBName;integrated security=True;MultipleActiveResultSets=True;Encrypt=False;App=DBName"
      }
    ]
  }
}
```

For **PostgreSQL**, change the `Provider` and `ConnectionString` accordingly:

```json
{
  "BiaNet": {
    "DatabaseConfigurations": [
      {
        "Key": "ProjectDatabase",
        "Provider": "PostGreSql",
        "ConnectionString": "Host=localhost;Database=DBName;Username=postgres;Password=yourpassword"
      }
    ]
  }
}
```

The `Key` value (`"ProjectDatabase"`) matches the constant `BiaConstants.DatabaseConfiguration.DefaultKey` used throughout the codebase to resolve the active connection. Do not change it unless you also update the constant.

The base `bianetconfig.json` stays minimal — it is only overridden per environment:

```json
{
  "BiaNet": {}
}
```

### `appsettings.json`

The base `appsettings.json` defines all defaults including the migration timeout and recurring job CRONs:

```json
{
  "DatabaseMigrate": {
    "CommandTimeout": 1
  },
  "Tasks": {
    "WakeUp":              { "CRON": "0 6-17 * * *" },
    "SynchronizeUser":     { "CRON": "0 6 * * *" },
    "CleanFileDownloadData": { "CRON": "0 * * * *" }
  },
  "Project": {
    "Name": "DBName",
    "ShortName": "DBName"
  }
}
```

`DatabaseMigrate:CommandTimeout` is in **minutes**. Increase it for large databases with long-running migrations.

---

## EF Core Migrations

### Architecture

BIA projects use a dedicated multi-project architecture that separates migration files per database provider. **DeployDB** is the single entry point for all migration operations.

| Project | Role |
|---|---|
| `Infrastructure.Data` | Defines `DataContext` / `DataContextPostGreSql` and the entity model |
| `Infrastructure.Data.Migrations.SqlServer` | Stores SQL Server–specific migration files |
| `Infrastructure.Data.Migrations.PostgreSQL` | Stores PostgreSQL-specific migration files |
| `DeployDB` | Applies migrations on startup; startup project (`-s`) for all EF CLI commands |

**Why does DeployDB reference both migration projects?**  
EF Core must be able to load the migration assembly at design time when running `dotnet ef` commands. Because DeployDB references both provider projects, its output directory always contains the two migration assemblies regardless of the configured provider.

```
DeployDB
├── Crosscutting.Ioc                             → configures DbContext + MigrationsAssembly per provider
├── Infrastructure.Data.Migrations.SqlServer     → SqlServer migration files
└── Infrastructure.Data.Migrations.PostgreSQL    → PostgreSQL migration files
```

### IoC Configuration

The whole wiring happens in `Program.cs` of DeployDB via a single call:

```csharp
// Program.cs (DeployDB)
IocContainer.BiaConfigureInfrastructureDataContainerDbContext(
    param,
    dbKey: BiaConstants.DatabaseConfiguration.DefaultKey, // "ProjectDatabase"
    fromDeployDB: true);
```

Setting `fromDeployDB: true` triggers a different registration path inside `BiaConfigureInfrastructureDataContainerDbContext()`. The full logic is:

```csharp
public static void BiaConfigureInfrastructureDataContainerDbContext(
    ParamIocContainer param,
    string dbKey = BiaConstants.DatabaseConfiguration.DefaultKey,
    bool enableRetryOnFailure = true,
    int commandTimeout = default,
    bool fromDeployDB = false)
{
    // Reads Provider + ConnectionString from bianetconfig.{env}.json
    string connectionString = param.Configuration.GetDatabaseConnectionString(dbKey);
    DbProvider dbEngine = param.Configuration.GetProvider(dbKey);

    // Always registers DataContext as IQueryableUnitOfWork (used by DeployDBService for cleanup tasks)
    param.Collection.AddDbContext<IQueryableUnitOfWork, DataContext>(options =>
    {
        ConfigureDbContextOptions(enableRetryOnFailure, commandTimeout, options, connectionString, dbEngine);
        // Note: audit interceptor is NOT added when fromDeployDB = true
    });

    if (!fromDeployDB)
    {
        // API / Worker path: also registers the read-only (no-tracking) context
        param.Collection.AddDbContext<IQueryableUnitOfWorkNoTracking, DataContextNoTracking>(...);
        return;
    }

    // DeployDB-specific path
    ConfigureDbContextForDeployDB(param.Collection, connectionString, dbEngine);
}
```

`ConfigureDbContextForDeployDB()` registers the migration-capable context as `IDbContextDatabase` and points EF Core to the correct provider-specific migration assembly:

```csharp
private static void ConfigureDbContextForDeployDB(
    IServiceCollection collection, string connectionString, DbProvider dbEngine)
{
    // Exposes the backend version in the EF migration history table (extended properties)
    collection.Configure<BiaHistoryRepositoryOptions>(options =>
    {
        options.AppVersion = Constants.Application.BackEndVersion;
    });

    if (dbEngine == DbProvider.PostGreSql)
    {
        collection.AddDbContext<IDbContextDatabase, DataContextPostGreSql>(options =>
        {
            options.UseNpgsql(connectionString, optionsBuilder =>
            {
                // Tells EF Core to look for migrations in the PostgreSQL-dedicated assembly
                optionsBuilder.MigrationsAssembly(Constants.DatabaseMigrations.AssemblyNamePostgreSQL);
                // → "[Company].[Project].Infrastructure.Data.Migrations.PostgreSQL"
            });
            // Custom history repository that writes extended properties to __EFMigrationsHistory
            options.ReplaceService<IHistoryRepository, BiaNpgsqlHistoryRepository>();
        });
    }
    else
    {
        collection.AddDbContext<IDbContextDatabase, DataContext>(options =>
        {
            options.UseSqlServer(connectionString, optionsBuilder =>
            {
                // Tells EF Core to look for migrations in the SqlServer-dedicated assembly
                optionsBuilder.MigrationsAssembly(Constants.DatabaseMigrations.AssemblyNameSqlServer);
                // → "[Company].[Project].Infrastructure.Data.Migrations.SqlServer"
            });
            // Custom history repository that writes extended properties to __EFMigrationsHistory
            options.ReplaceService<IHistoryRepository, BiaSqlServerHistoryRepository>();
        });
    }
}
```

The assembly name constants are defined in `Crosscutting.Common/Constants.cs`:

```csharp
public static class DatabaseMigrations
{
    public const string AssemblyNameSqlServer =
        "[Company].[Project].Infrastructure.Data.Migrations.SqlServer";

    public const string AssemblyNamePostgreSQL =
        "[Company].[Project].Infrastructure.Data.Migrations.PostgreSQL";
}
```

> **Why a separate context for PostgreSQL?**  
> `DataContextPostGreSql` inherits from `DataContext` and overrides `OnConfiguring` to force Npgsql. This lets the EF CLI target it with `-c DataContextPostGreSql` while keeping a single shared entity model defined in `DataContext`.

#### Services registered by `fromDeployDB: true` vs normal mode

| Registration | API / Worker (`fromDeployDB: false`) | DeployDB (`fromDeployDB: true`) |
|---|---|---|
| `IQueryableUnitOfWork` → `DataContext` | ✅ with audit interceptor | ✅ without audit interceptor |
| `IQueryableUnitOfWorkNoTracking` → `DataContextNoTracking` | ✅ | ❌ |
| `IDbContextDatabase` → provider-specific context | ❌ | ✅ with `MigrationsAssembly` |
| `IHistoryRepository` → custom Bia history repo | ❌ | ✅ |

### Applying Migrations (Update Database)

**Launch the DeployDB project.** On startup, `DeployDBService` automatically runs:

```csharp
// DeployDBService.cs
this.dbContextDatabase.SetCommandTimeout(TimeSpan.FromMinutes(timeout)); // from appsettings.json
this.dbContextDatabase.Migrate(); // applies all pending migrations
await this.dbContextDatabase.RunScriptsFromAssemblyEmbeddedResourcesFolder(
    typeof(DataContext).Assembly, "Scripts.PostDeployment"); // runs SQL post-deployment scripts
```

After the migration completes, the process stops automatically.

### Creating Migrations (EF CLI)

Use `dotnet ef migrations add` with **DeployDB as the startup project** (`-s`). The provider is resolved from `bianetconfig.Development.json` inside the DeployDB project.

> **Important:** the `Provider` field in `bianetconfig.Development.json` must match the context you target:
> - `"SQLServer"` → `-c DataContext`
> - `"PostGreSql"` → `-c DataContextPostGreSql`

#### SQL Server

```bash
dotnet ef migrations add {MigrationName} \
  --project [Company].[Project].Infrastructure.Data.Migrations.SqlServer \
  -s [Company].[Project].DeployDB \
  -c DataContext
```

#### PostgreSQL

```bash
dotnet ef migrations add {MigrationName} \
  --project [Company].[Project].Infrastructure.Data.Migrations.PostgreSQL \
  -s [Company].[Project].DeployDB \
  -c DataContextPostGreSql
```

### VS Code Tasks

The DotNet workspace `tasks.json` exposes pre-configured tasks. Access them via **Terminal › Run Task…** or `Ctrl+Shift+P` → *Tasks: Run Task*.

| Task | Description |
|---|---|
| `Database Add migration SqlServer` | Prompts for a name and adds a SQL Server migration |
| `Database Add migration PostGreSql` | Prompts for a name and adds a PostgreSQL migration |
| `Database Udpate SqlServer` | Applies all pending SQL Server migrations via EF CLI |
| `Database Rollback SqlServer` | Rolls back SQL Server to a target migration (prompts for name) |
| `Database Remove last migration SqlServer` | Removes the last SQL Server migration |
| `Database Remove last migration PostGreSql` | Removes the last PostgreSQL migration |

---

## Development Workflow Optimisation

For feature development that does **not** require database schema changes, load the **lightweight solution filter**:

```
[Project]_WithoutDeployDB.slnf
```

This filter excludes `DeployDB`, `Infrastructure.Data.Migrations.SqlServer` and `Infrastructure.Data.Migrations.PostgreSQL` from the solution, which:

- skips Roslyn analysis of hundreds of generated migration files → faster IDE
- reduces build time and memory footprint

| Situation | Solution to load |
|---|---|
| Feature development, no DB schema changes | `…_WithoutDeployDB.slnf` |
| Adding or modifying the DB schema | Full `….sln` |
