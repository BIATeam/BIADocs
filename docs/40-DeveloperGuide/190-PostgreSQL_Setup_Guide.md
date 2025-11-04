---
sidebar_position: 190
---

# PostgreSQL Setup Guide

## Overview

This guide explains how to configure PostgreSQL for the BIA project. The project supports both SQL Server and PostgreSQL providers, with specific configurations for different user types and authentication methods.

## Database Creation

**Important**: You must manually create the database in PostgreSQL before running migrations or deployments.

## User Management

### Owner User (Full Privileges)

The owner user has complete control over the database, including schema modifications, table creation, and data manipulation. This user is required for migrations and database deployments.

```sql
-- Create owner user with full privileges
CREATE USER "PostGreSQL_U" WITH PASSWORD 'xxxxxxxxxxxxxxxxxxx';

-- Grant all privileges on the database
GRANT ALL ON DATABASE "BIADemo" TO "PostGreSQL_U";

-- Grant all privileges on the public schema
GRANT ALL ON SCHEMA public TO "PostGreSQL_U";

-- Grant privileges on all existing and future tables in public schema
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "PostGreSQL_U";

-- Grant privileges on all existing and future sequences in public schema
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "PostGreSQL_U";

-- Optional: If using Hangfire (uncomment if needed)
-- GRANT ALL ON SCHEMA hangfire TO "PostGreSQL_U";
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA hangfire TO "PostGreSQL_U";
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA hangfire TO "PostGreSQL_U";
```

#### Removing Owner User

```sql
-- Drop all objects owned by the user and then drop the user
DROP OWNED BY "PostGreSQL_U" CASCADE;
DROP USER "PostGreSQL_U";
```

### Read-Write User (Limited Privileges)

The read-write user has permissions to read and modify data but cannot alter the database schema. This user is suitable for runtime application operations.

```sql
-- Create read-write user
CREATE USER "PostGreSQL_RW" WITH PASSWORD 'xxxxxxxxxxxxxxxxxxx';

-- Grant read and write permissions (PostgreSQL 14+ built-in roles)
GRANT pg_read_all_data TO "PostGreSQL_RW";
GRANT pg_write_all_data TO "PostGreSQL_RW";
```

#### Removing Read-Write User

```sql
-- Drop all objects owned by the user and then drop the user
DROP OWNED BY "PostGreSQL_RW" CASCADE;
DROP USER "PostGreSQL_RW";
```

## Connection String Configuration

The BIA project supports different connection string configurations in the `bianetconfig.json` file:

### 1. Direct Connection (Static Credentials)

Use this configuration when you want to embed credentials directly in the connection string.

```json
{
  "Key": "ProjectDatabase",
  "Provider": "PostgreSQL",
  "ConnectionString": "Host=localhost;Database=BIADemo;Username=postgres;Password=xxxxxxxxxxxxxxxxx"
}
```

**Use Case**: Development environments where security is less critical.

### 2. Owner User with Vault Credentials

Use this configuration for database migrations and deployments where full privileges are required.

```json
{
  "Key": "ProjectDatabase",
  "Provider": "PostgreSQL",
  "ConnectionString": "Host=localhost;Database=BIADemo;Username={login};Password={password}",
  "CredentialSource": {
    "VaultCredentialsKey": "BIA:PostGreSQL_U"
  }
}
```

**Use Case**: 
- Running Entity Framework migrations
- Database deployments via DeployDB project
- Administrative operations requiring schema changes

### 3. Read-Write User with Vault Credentials

Use this configuration for runtime application operations where only data access is needed.

```json
{
  "Key": "ProjectDatabase",
  "Provider": "PostgreSQL",
  "ConnectionString": "Host=localhost;Database=BIADemo;Username={login};Password={password}",
  "CredentialSource": {
    "VaultCredentialsKey": "BIA:PostGreSQL_RW"
  }
}
```

**Use Case**:
- Production runtime operations
- API data access
- Regular application functionality

### Configuration Differences Explained

| Configuration | User Type | Privileges | Use Case |
|---------------|-----------|------------|----------|
| Direct Connection | Any (typically postgres) | Full or Limited | Development, testing |
| Owner User (PostGreSQL_U) | Owner | Full database control | Migrations, deployments |
| Read-Write User (PostGreSQL_RW) | Application | Data access only | Runtime operations |

## Entity Framework Migrations

### Prerequisites

Before creating migrations, ensure:
1. The database exists in PostgreSQL
2. You're using the **Owner User** configuration (PostGreSQL_U)
3. The **API project** is set as the startup project
4. The **Data project** is selected in Package Manager Console

### Creating Migrations

To create a new migration for PostgreSQL:

---

#### Migration with Visual Studio (NuGet Package Manager Console)

1. **Set the startup project**: Right-click on `TheBIADevCompany.BIADemo.Presentation.Api` → "Set as Startup Project"
2. **Open Package Manager Console**: Tools → NuGet Package Manager → Package Manager Console
3. **Select the correct project**: In Package Manager Console, set "Default Project" to `TheBIADevCompany.BIADemo.Infrastructure.Data`
4. **Run the migration command**:
  ```powershell
  Add-Migration Initial -Context DataContextPostGreSql -OutputDir MigrationsPostGreSql
  ```

---

#### Migration with .NET CLI

If you prefer to use the .NET CLI instead of Visual Studio, use the following command for PostgreSQL:

```powershell
dotnet ef migrations add Initial --context DataContextPostGreSql --output-dir MigrationsPostGreSql --project A3DR.BFF.Infrastructure.Data --startup-project A3DR.BFF.Presentation.Api
```

Replace `Initial` with your migration name. Adjust the project paths if needed.

### Migration Command Parameters

- `Initial`: Name of the migration (replace with descriptive name)
- `-Context DataContextPostGreSql`: Specifies the PostgreSQL-specific DbContext
- `-OutputDir MigrationsPostGreSql`: Directory for PostgreSQL migrations (separate from SQL Server migrations)

### Example Migration Commands

```powershell
# Initial migration
Add-Migration Initial -Context DataContextPostGreSql -OutputDir MigrationsPostGreSql

# Feature-specific migration
Add-Migration AddUserDefaultTeams -Context DataContextPostGreSql -OutputDir MigrationsPostGreSql

# Schema update migration
Add-Migration UpdateEngineRelationships -Context DataContextPostGreSql -OutputDir MigrationsPostGreSql
```

### Migration File Structure

Migrations are organized in separate directories:
- SQL Server migrations: `Migrations/`
- PostgreSQL migrations: `MigrationsPostGreSql/`
