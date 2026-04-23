---
sidebar_position: 135
---

# Migration History Table Extended Properties

BIA Framework can extend the Entity migration history table for **SQLServer** and **PostgreSQL** providers with following properties :
- **AppVersion** : your application version
- **MigratedAt** : UTC date of the executed migration

## Enable into project
### Dependency Injection
Into your **Crosscutting.Ioc** project, open the `IocContainer.cs` file and configure as follow :
``` csharp title="IocContainer.cs"
namespace TheBIADevCompany.BIADemo.Crosscutting.Ioc
{
    public static class IocContainer
    {
        // [...]

        private static void ConfigureInfrastructureDataContainer(IServiceCollection collection, IConfiguration configuration, bool isUnitTest)
        {
            if (!isUnitTest)
            {
                // [...]

                // Configure the options of the BIA History Repository
                collection.Configure<BiaHistoryRepositoryOptions>(options =>
                {
                    // Map your application version here
                    options.AppVersion = Constants.Application.BackEndVersion;
                });

                // SQLServer configuration example
                collection.AddDbContext<IQueryableUnitOfWork, DataContext>(options =>
                {
                    if (connectionString != null)
                    {
                        options.UseSqlServer(connectionString);
                        // Replace here the default history repository by the BIA history repository for SQLServer
                        options.ReplaceService<IHistoryRepository, BiaSqlServerHistoryRepository>();
                    }

                    // [...]
                });

                // NPGSQL configuration example
                collection.AddDbContext<IQueryableUnitOfWork, DataContext>(options =>
                {
                    if (connectionString != null)
                    {
                        options.UseNpgsql(connectionString);
                        // Replace here the default history repository by the BIA history repository for NPGSQL
                        options.ReplaceService<IHistoryRepository, BiaNpgsqlHistoryRepository>();
                    }

                    // [...]
                });
            }

            // [...]
        }

        // [...]
    }
}
```

:::info
The configuration for **SQLServer** is the default one implemented for all new BIA Framework projects since BIA Framework **V6**
:::

### Migration for existing projects
:::warning
This chapter is only applicable for projects migrated from BIA Framework versions under **V6** with **SQL Server** and **PostgreSQL** database providers.
:::

You must create a custom migration in order to adapt your migration history table schema to the new extended properties seen as below :
1. Create a new migration : `add-migration -c datacontext ExtendMigrationHistoryTable`
2. Replace the empty content of the generated migration by the following snippet :
``` csharp
    public partial class ExtendMigrationHistoryTable : Migration
    {
        private const string HistoryTable = "__EFMigrationsHistory";

        protected override void Up(MigrationBuilder migrationBuilder)
        {
            if (migrationBuilder.IsSqlServer())
            {
                migrationBuilder.Sql($@"
IF COL_LENGTH(N'{HistoryTable}', N'AppVersion') IS NULL
BEGIN
    ALTER TABLE [{HistoryTable}] ADD [AppVersion] nvarchar(64) NULL;
END;

IF COL_LENGTH(N'{HistoryTable}', N'MigratedAt') IS NULL
BEGIN
    ALTER TABLE [{HistoryTable}] ADD [MigratedAt] datetime2 NULL;
END;

IF COL_LENGTH(N'{HistoryTable}', N'MigratedAt') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.default_constraints dc
    JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
    WHERE OBJECT_NAME(dc.parent_object_id) = '{HistoryTable}' AND c.name = 'MigratedAt'
)
BEGIN
    ALTER TABLE [{HistoryTable}]
        ADD CONSTRAINT [DF_{HistoryTable}_MigratedAt] DEFAULT (sysutcdatetime()) FOR [MigratedAt];
END;
");
            }
            else if (migrationBuilder.IsNpgsql())
            {
                migrationBuilder.Sql($@"
ALTER TABLE ""{HistoryTable}""
    ADD COLUMN IF NOT EXISTS ""AppVersion"" character varying(64) NULL;

ALTER TABLE ""{HistoryTable}""
    ADD COLUMN IF NOT EXISTS ""MigratedAt"" timestamp with time zone NULL;

ALTER TABLE ""{HistoryTable}""
    ALTER COLUMN ""MigratedAt"" SET DEFAULT now();
");
            }
            else
            {
                throw new NotSupportedException($"Not supported provider : {migrationBuilder.ActiveProvider}");
            }
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            if (migrationBuilder.IsSqlServer())
            {
                migrationBuilder.Sql($@"
DECLARE @df sysname;
SELECT @df = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE OBJECT_NAME(dc.parent_object_id) = '{HistoryTable}' AND c.name = 'MigratedAt';
IF @df IS NOT NULL
    EXEC('ALTER TABLE [{HistoryTable}] DROP CONSTRAINT [' + @df + ']');

IF COL_LENGTH(N'{HistoryTable}', N'MigratedAt') IS NOT NULL
    ALTER TABLE [{HistoryTable}] DROP COLUMN [MigratedAt];

IF COL_LENGTH(N'{HistoryTable}', N'AppVersion') IS NOT NULL
    ALTER TABLE [{HistoryTable}] DROP COLUMN [AppVersion];
");
            }
            else if (migrationBuilder.IsNpgsql())
            {
                migrationBuilder.Sql($@"
ALTER TABLE ""{HistoryTable}""
    ALTER COLUMN ""MigratedAt"" DROP DEFAULT;

ALTER TABLE ""{HistoryTable}""
    DROP COLUMN IF EXISTS ""MigratedAt"";

ALTER TABLE ""{HistoryTable}""
    DROP COLUMN IF EXISTS ""AppVersion"";");
            }
            else
            {
                throw new NotSupportedException($"Not supported provider : {migrationBuilder.ActiveProvider}");
            }
        }
    }
```
3. Udate your database with `update-database -context datacontext`
4. Ensure that your migration history table have now the two extended properties `AppVersion` and `MigratedAt`
5. Ensure that your last migration have filled `MigratedAt`. Ignore `AppVersion` content that should be empty at time
  
