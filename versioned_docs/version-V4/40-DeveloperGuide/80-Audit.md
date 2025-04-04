---
sidebar_position: 80
---

# Audit
This file explains how to activate/deactivate the audit feature (users' modifications tracing) and how to customize it.

## Prerequisite

### Knowledge to have:
The audit feature is actively using the **Audit.NET** library
* [Audit.NET github site](https://github.com/thepirat000/Audit.NET)
* [Audit.NET documentation](https://github.com/thepirat000/Audit.NET/blob/master/README.md)
* [Audit.EntityFramework documentation](https://github.com/thepirat000/Audit.NET/blob/master/src/Audit.EntityFramework/README.md)
* [Audit.NET.SqlServer documentation](https://github.com/thepirat000/Audit.NET/blob/master/src/Audit.NET.SqlServer/README.md)

## Overview
The audit feature, by default, stores the modifications (and the user who has done these modifications) done on entity objects in a dedicated **Events** table of the default database.

## Activation/Deactivation
* to activate/deactivate the feature modify the "IsActive" property in the following part of the bianetconfig file:
```
  "AuditConfiguration": {
    "IsActive": true,
    "ConnectionStringName": "ProjectDatabase"      
  }
```      

## Configuration and Customizing:
* In the Domain project the entities class to be audited shall be tag by 
```csharp
    /// <summary>
    /// The user entity.
    /// </summary>
    [AuditInclude]
    public class User : VersionedTable, IEntity<int>
```
* If you want to ignore change on a field you can use before the filed the tag [AuditIgnore]
```csharp

        /// <summary>
        /// Gets or sets the last login date.
        /// </summary>
        [AuditIgnore]
        public DateTime? LastLoginDate { get; set; }
``` 

* By default all audited table change are log in the table "AuditLog"
* Except User that is log in UserAudit table

The usage of a dedicated table simplify the history of change in a user interface. If you need it for other tables :

* To add your custom Audit table that inherit of AuditEntity and with all the field you want to log. Ex :
```csharp
    /// <summary>
    /// The user entity.
    /// </summary>
    public class UserAudit : AuditEntity, IEntity<int>
    {
        /// <summary>
        /// Gets or sets the id.
        /// </summary>
        public int AuditId { get; set; }

        /// <summary>
        /// Gets or sets the id.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Gets or sets the first name.
        /// </summary>
        public string FirstName { get; set; }

        /// <summary>
        /// Gets or sets the last name.
        /// </summary>
        public string LastName { get; set; }

        /// <summary>
        /// Gets or sets the login.
        /// </summary>
        public string Login { get; set; }

        /// <summary>
        /// Gets or sets the domain.
        /// </summary>
        public string Domain { get; set; }
    }
```
* customize the ..Infrastructure.Data/Features/AuditFeature to map the entity with the custom audit table. change the code in "AuditTypeMapper"
```csharp
        .AuditTypeMapper(type => AuditTypeMapper(type))

...

        private static Type AuditTypeMapper(Type type)
        {
            switch (type.Name)
            {
                case "User":
                    return typeof(UserAudit);
                case "MyEntity":
                    return typeof(MyEntityAudit);
                default:
                    return typeof(AuditLog);
            }
        }
```

# Switch Id to longInt (Optional)
If required you can switch the Id from int to longInt:
## Transform the AuditLog entity
Update AuditLog.cs : use long in the inheritance IEntity and in the Id type
```csharp
    /// <summary>
    /// The airport entity.
    /// </summary>
    public class AuditLog : AuditEntity, IEntity<long>
    {
        /// <summary>
        /// Gets or sets the id.
        /// </summary>
        public long Id { get; set; }
```

## Generate the migration
Add-Migration "AuditLongId" -Context "DataContext"

## Adapt the migration
Due to a known bug in ef5.0 you have to add manually the remove of the PrimaryKey and ForeignKey on each element modified, and recreate them after change in Up and Down function.
```csharp
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TheBIADevCompany.BIADemo.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AuditLongId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Begin Manually Added
            migrationBuilder.DropPrimaryKey(
                name: "PK_AuditLogs",
                table: "AuditLogs");
            // End Manually Added

            migrationBuilder.AlterColumn<long>(
                name: "Id",
                table: "AuditLogs",
                type: "bigint",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int")
                .Annotation("SqlServer:Identity", "1, 1")
                .OldAnnotation("SqlServer:Identity", "1, 1");

            // Begin Manually Added
            migrationBuilder.AddPrimaryKey(
                name: "PK_AuditLogs",
                table: "AuditLogs",
                column: "Id");
            // End Manually Added
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Begin Manually Added
            migrationBuilder.DropPrimaryKey(
                name: "PK_AuditLogs",
                table: "AuditLogs");
            // End Manually Added

            migrationBuilder.AlterColumn<int>(
                name: "Id",
                table: "AuditLogs",
                type: "int",
                nullable: false,
                oldClrType: typeof(long),
                oldType: "bigint")
                .Annotation("SqlServer:Identity", "1, 1")
                .OldAnnotation("SqlServer:Identity", "1, 1");

            // Begin Manually Added
            migrationBuilder.AddPrimaryKey(
                name: "PK_AuditLogs",
                table: "AuditLogs",
                column: "Id");
            // End Manually Added
        }
    }
}
```