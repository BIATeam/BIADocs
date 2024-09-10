---
sidebar_position: 1
---

# Database Handler (Worker Feature)
This file explains what to use the the database handler feature in your V3 project.

## Introduction
The database handlers can work in two modes :
- Using polling (default mode)
- Using SQL Data Broker (see [Prerequisite](#sql-data-broker-prerequisite))

Polling mode is compatible with SQL Server and PostgreSQL.
SQL Data Broker is only compatible with SQL Server with mandatory configuration as seen in the [Prerequisite](#sql-data-broker-prerequisite).

## SQL Data Broker Prerequisite
The user **sa** must be the owner of the database:

```SQL
ALTER AUTHORIZATION ON DATABASE::YourProjectDatabase TO sa;
GO
```

### Knowledge to have:
* [SQL language](https://sql.sh/)

### Database:
* The project database should be SQL Server
* Broker should be enable on the project database
```SQL
ALTER DATABASE [YourProjectDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE [YourProjectDatabase] SET ENABLE_BROKER;
ALTER DATABASE [YourProjectDatabase] SET MULTI_USER WITH ROLLBACK IMMEDIATE
```

**WARNING**: If the database is in an availability group, you should remove the database from availability group before apply this script.
And readd it after (required to delete before the database in secondary server).

Give the right to the YourUserRW to read and write the database and run this script (replace the YourUserRW by the corresponding user):
 
```SQL
USE [YourProjectDatabase];

--create user for schema ownership
CREATE USER SqlDependencySchemaOwner WITHOUT LOGIN;
GO

--create schema for SqlDependency objects
CREATE SCHEMA SqlDependency AUTHORIZATION SqlDependencySchemaOwner;
GO

--set the default schema of minimally privileged user to SqlDependency
ALTER USER "YourUserRW" WITH DEFAULT_SCHEMA = SqlDependency;

--grant user control permissions on SqlDependency schema
GRANT CONTROL ON SCHEMA::SqlDependency TO "YourUserRW";

--grant user impersonate permissions on SqlDependency schema owner
GRANT IMPERSONATE ON USER::SqlDependencySchemaOwner TO "YourUserRW";
GO

--grant database permissions needed to create and use SqlDependency objects
GRANT CREATE PROCEDURE TO "YourUserRW";
GRANT CREATE QUEUE TO "YourUserRW";
GRANT CREATE SERVICE TO "YourUserRW";
GRANT REFERENCES ON
    CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] TO "YourUserRW";
GRANT VIEW DEFINITION TO "YourUserRW";
GRANT SELECT to "YourUserRW";
GRANT SUBSCRIBE QUERY NOTIFICATIONS TO "YourUserRW";
GRANT RECEIVE ON QueryNotificationErrorsQueue TO "YourUserRW";
GO
```

## Database Handler Overview
* The worker service run code when there is change on the database.
* A fine selection of the rows to track can be done with a query.

## Activation
* **bianetconfig.json**
In the BIANet Section add:
``` json
    "WorkerFeatures": {
      "DatabaseHandler": {
        "Activate": true
      }
    },
```

## Usage
### Create the handler repositories
For each request to track in database, create a repository class in the worker project in folder Features. This class must inherits from `DatabaseHandlerRepository<T>` that implements the interface `IDatabaseHandlerRepository` :
```csharp 
namespace [YourCompanyName].[YourProjectName].WorkerService.Features
{
    using System;
    using System.Collections.Generic;
    using System.Threading.Tasks;
    using BIA.Net.Core.Common.Configuration;
    using BIA.Net.Core.WorkerService.Features.DataBaseHandler;
    using Microsoft.Data.SqlClient;
    using Microsoft.Extensions.Configuration;

    public class DemoHandlerRepository : DatabaseHandlerRepository<DemoHandlerRepository>
    {
        public DemoHandlerRepository(IServiceProvider serviceProvider, IConfiguration configuration)
            : base(
                  serviceProvider,
                  configuration.GetConnectionString("DemoDatabase"),
                  configuration.GetDBEngine("DemoDatabase"),
                  "SELECT Id, Name, RowVersion FROM [dbo].[Users]",
                  "Id",
                  pollingInterval: TimeSpan.FromSeconds(1),
                  useSqlDataBroker: configuration.GetSqlDataBroker("DemoDatabase"),
                  sqlFilterNotificationInfos: new List<SqlNotificationInfo> { SqlNotificationInfo.Delete, SqlNotificationInfo.Update, SqlNotificationInfo.Insert })
        {
        }

        protected override Task OnChange(DataBaseHandlerChangedData changedData)
        {
            string userName;
			if (changedData.ChangeType == DatabaseHandlerChangeType.Delete && changedData.PreviousData.TryGetValue("Name", out object oldUsername))
			{
				userName = (string)oldUsername;
			}
			else if (changedData.CurrentData.TryGetValue("Name", out object currentUserName))
			{
				userName = (string)currentUserName;
			}

			Debug.WriteLine($"User {userName} has changed !")
            return Task.CompletedTask;
        }
    }
}
```
#### Mandatory constructor parameters :
- **serviceProvider** : injected with dependency injection
- **configuration** : injected with dependency injection

#### Mandatory base override methods :
- **OnChange** : method called when changes has been detected by the handler. `DataBaseHandlerChangedData` parameter represents the affected row with the change type (Add, Delete or Modify), previous and current value as `Dictionary<string, object>` where the key is the column name and the value the column value.

#### Mandatory base constructor parameters :
- **serviceProvider** : to use injected service provider of inherited class
- **connectionString** : to connect to the database
- **databaseEngine** : type of database engine (sqlserver or postgresql)
- **onChangeEventHandlerRequest** : the query to track changes. Each column to track and include into the changes must be namely specified
- **indexKey** : the index key of the query to track. Must be included in the query

#### Optional base constructor parameters :
- **useSqlDataBroker** : force the use of SQL Data Broker mode if true (false by default)
- **pollingInterval** : set the interval of polling (default is 5 seconds)
- **sqlFilterNotificationInfos** : list of valid `SqlNotificationInfo` sent by SQL Server when using SQL Data Broker mode that triggers the detection of changes. If null or empty, all `SqlNotificationInfo` will be treated as valid.

#### Using SQL Data Broker
* **appsettings.json**
Add a section SQLDataBroker below DBEngine section :
``` json
    "SQLDataBroker": {
  		"DemoDatabase": "true"
	},
```

### Parameters those repositories
In Startup you should inject all the implementations of the `IDatabaseHandlerRepository` as **singleton** :
``` csharp
services.AddSingleton<IDatabaseHandlerRepository, DemoHandlerRepository>();
services.AddSingleton<IDatabaseHandlerRepository, OtherHandlerRepository>();
```

