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
To activate/deactivate the feature modify the "IsActive" property in the following part of the bianetconfig file:
``` json
  "AuditConfiguration": {
    "IsActive": true,
    "ConnectionStringName": "ProjectDatabase"      
  }
```      

## Configuration
### Enable Entity Audit
1. For each entity to audit, add the attribute `[AuditInclude]` on the class definition :
```csharp title="MyEntity.cs"
[AuditInclude]
public class MyEntity : BaseEntity<int>
{
    public string AuditedProperty { get; set; }
}
```
2. All the entity's properties will be included into audit changes
3. If you want to ignore one, add the attribute `[AuditIgnore]` on the property definition :
```csharp title="MyEntity.cs"
[AuditInclude]
public class MyEntity : BaseEntity<int>
{
    public string AuditedProperty { get; set; }

    [AuditIgnore]
    public string AuditIgnoredProperty { get; set; }
}
```
:::tip
By default, only the raw values ​​of properties in the audited entity table will be affected by audit changes.  

This means that changes to **Many-To-Many** and **One-To-Many** relationships <u>will not be included</u>, and changes to **Many-To-One** or **One-To-One** relationships will only affect the linkage index value.  

See [linked entities configuration chapter](#configure-audit-linked-entities) for custom solution.
:::
### Audit Storage Location
#### AuditLog table
By default, all audited entities will be stored into `AuditLogs` table :
| Id | Table | PrimaryKey | RowVersion | AuditDate | AuditAction | AuditChanges | AuditUserLogin |
| -- | -- | -- | -- | -- | -- | -- | -- |
| 1 | MyEntities | \{"Id":1\} | 0x000000000000082C | 2025-01-28 14:04:20.1660368 | Insert | \{"Id":1,"AuditedProperty":"Something"\} | Admin |
| 2 | MyEntities | \{"Id":1\} | 0x000000000000082D | 2025-01-28 14:05:20.1660368 | Update | [\{"ColumnName":"AuditedProperty","OriginalValue":"Something","NewValue":"Another thing"\}] | Admin |
| 3 | MyEntities | \{"Id":1\} | 0x000000000000082E | 2025-01-28 14:06:20.1660368 | Delete | \{"Id":1,"AuditedProperty":"Another thing"\} | Admin |

- **Id** : the Id of the audit log
- **Table** : table of the audited entity
- **PrimaryKey** : JSON of all PK of the audited entity
- **RowVersion** : row version of the audit log
- **AuditDate** : date of the audit log
- **AuditAction** : action of the audit log : `Insert` | `Update` | `Delete`
- **AuditChanges** : changes of the audit log
  - JSON of the audited entity in case of `Insert` or `Delete` action
  - For `Update` action, JSON of all the audited changes of the entity with `ColumnName`, `OriginalValue` and `NewValue`
- **AuditUserLogin** : user login that triggered the entity audit log

#### Dedicated Audit table
The usage of a dedicated table simplify the history of change in a user interface, and mandatory when displaying the historical of an entity.

1. Create your own audit entity into same namespace as your entity, and inherits from `AuditEntity<TEntity>` class where `TEntity` is your audited entity class :
```csharp title="MyEntityAudit.cs"
public class MyEntityAudit : AuditEntity<MyEntity>
{
}
```
2. Add the same properties as your audited entity to store the values into dedicated columns :
```csharp title="MyEntityAudit.cs"
public class MyEntityAudit : AuditEntity<MyEntity>
{
    public string AuditedProperty { get; set; }
}
```
3. You can add custom properties to fill with the audited entity values by overidding the `FillSpecificProperties` method :
```csharp title="MyEntityAudit.cs"
public class MyEntityAudit : AuditEntity<MyEntity>
{
    public string AuditedProperty { get; set; }
    public int CustomProperty { get; set; }

    protected override void FillSpecificProperties(MyEntity entity)
    {
        this.CustomProperty = entity.Id + 1;
    }
}
```
4. Customize the `AuditFeature` class to map the entity with the custom audit table :
```csharp title="AuditFeature.cs"
public class AuditFeature(IOptions<CommonFeatures> commonFeaturesConfigurationOptions, IServiceProvider serviceProvider) : BaseAuditFeature(commonFeaturesConfigurationOptions, serviceProvider)
{
    public override Type AuditTypeMapper(Type type)
    {
        return type.Name switch
        {
            nameof(MyEntity) => typeof(MyEntityAudit),
            _ => base.AuditTypeMapper(type),
        };
    }
}
```
:::info
Unmapped dedicated audit entities will be mapped as `AuditLog`
:::

5. Add into your `DataContext` the `DbSet` of your audit entity :
```csharp title="DataContext.cs"
public class DataContext : BiaDataContext
{
    public DbSet<MyEntityAudit> MyEntityAudits { get; set; }
}
```

6. Complete into `AuditModelBuilder` the configuration of your audit entity :
```csharp title="AuditModelBuilder.cs"
public class AuditModelBuilder : BaseAuditModelBuilder
{
    public void CreateModel(ModelBuilder modelBuilder)
    {
        this.CreateAuditModel(modelBuilder);
        this.CreateUserAuditModel<UserAudit, User>(modelBuilder);

        // Mandatory
        modelBuilder.Entity<MyEntityAudit>().Property(p => p.EntityId).IsRequired();
    }
}
```

Your dedicated audit table will following this kind of scheme :
| Id | RowVersion | AuditDate | AuditAction | AuditChanges | AuditUserLogin | EntityId | LinkedEntities | AuditedProperty | CustomProperty |
| -- | -- | -- | -- | -- | -- | -- | -- | -- | -- |
| 1 | 0x000000000000082C | 2025-01-28 14:04:20.1660368 | Insert | [\{"ColumnName":"AuditedProperty","OriginalValue":null,"OriginalDisplay":null,"NewValue":"Something","NewDisplay":"Something"\}] | Admin | 1 | | Something | 2 |
| 2 | 0x000000000000082D | 2025-01-28 14:04:21.1660368 | Update | [\{"ColumnName":"AuditedProperty","OriginalValue":"Something","OriginalDisplay":Something,"NewValue":"Another thing","NewDisplay":"Another thing"\}] | Admin | 1 | | Another thing | 2 |
| 3 | 0x000000000000082E | 2025-01-28 14:04:22.1660368 | Delete | \{"Id":1,"AuditedProperty":"Another thing"\} | Admin | 1 | | Another thing | 2 |

- **Id** : the Id of the audit log
- **RowVersion** : row version of the audit log
- **AuditDate** : date of the audit log
- **AuditAction** : action of the audit log : `Insert` | `Update` | `Delete`
- **AuditChanges** : changes of the audit log
  - JSON of the audited entity in case of `Delete` action
  - For `Insert` or `Update` action, JSON of all the audited changes of the entity with `ColumnName`, `OriginalValue` and `NewValue`. `OriginalDisplay` and `NewDisplay` are the specific displayed values of the changes.
- **AuditUserLogin** : user login that triggered the entity audit log
- **EntityId** : identifier of the audited entity
- **LinkedEntities** : JSON of all linked entities data related to the audited one, with the `EntityType`, `IndexPropertyName` and `IndexPropertyValue`. See [next chapter](#configure-audit-linked-entities).
- **AuditedProperty** : according to the current example, corresponds to the `AuditedProperty` value of the audited entity
- **CustomProperty** : according to the current example, corresponds to the `CustomProperty` value of the audited entity

## Configure Audit Linked Entities
:::warning
Only compatible for entities with [Dedicated Audit Tables](#dedicated-audit-table)
:::

When auditing entity changes, you can't audit by default the changes happening to the entity's references.  
This chapter explains how to configure the audit of linked entities of your audited entity.

### Many-To-Many
Given the following example :
```csharp title="MyEntity.cs"
[AuditInclude]
public class MyEntity : BaseEntity<int>
{
    public string AuditedProperty { get; set; }
    public ICollection<MyLinkedEntity> LinkedEntities { get; set; } 
    public ICollection<MyEntityMyLinkedEntity> JoinLinkedEntities { get; set; } 
}
```
```csharp title="MyLinkedEntity.cs"
public class MyLinkedEntity : BaseEntity<int>
{
    public string LinkedAuditedProperty { get; set; }
}
```
```csharp title="MyEntityMyLinkedEntity.cs"
public class MyEntityMyLinkedEntity
{
    public int MyEntityId { get; set; }
    public MyEntity MyEntity { get; set; }
    public int MyLinkedEntityId { get; set; }
    public MyLinkedEntity MyLinkedEntity { get; set; }
}
```

1. Add `[AuditInclude]` attribute onto your join entity class :
```csharp title="MyEntityMyLinkedEntity.cs"
[AuditInclude]
public class MyEntityMyLinkedEntity
{
    // [...]
}
```

2. Create dedicated audit entity for your join entity class (follow all the steps [here](#dedicated-audit-table)) :
```csharp title="MyEntityMyLinkedEntityAudit.cs"
public class MyEntityMyLinkedEntityAudit : AuditEntity<MyEntityMyLinkedEntity>
{
}
```

3. Add the primary key index properties into your dedicated join audit entity with attribute `[AuditLinkedEntityPropertyIdentifier]` :
```csharp title="MyEntityMyLinkedEntityAudit.cs"
public class MyEntityMyLinkedEntityAudit : AuditEntity<MyEntityMyLinkedEntity>
{
    [AuditLinkedEntityPropertyIdentifier(linkedEntityType: typeof(MyEntity))]
    public int MyEntityId { get; set; }

    [AuditLinkedEntityPropertyIdentifier(linkedEntityType: typeof(MyLinkedEntity))]
    public int MyLinkedEntityId { get; set; }
}
```
- **linkedEntityType** : the linked entity type that refers to the primary key index
:::info
Each `[AuditLinkedEntityPropertyIdentifier]` property will add data into the `LinkedEntities` column of the audited entity table.
:::
:::tip
You can't add multiple `[AuditLinkedEntityPropertyIdentifier]` for the same identifier property.
:::

The dedicated audit table will be like this :
| Id | RowVersion | AuditDate | AuditAction | AuditChanges | AuditUserLogin | EntityId | LinkedEntities | MyEntityId | MyLinkedEntityId |
| -- | -- | -- | -- | -- | -- | -- | -- | -- | -- |
| 1 | 0x000000000000082C | 2025-01-28 14:04:20.1660368 | Insert | [\{"ColumnName":"MyEntityId","OriginalValue":null,"OriginalDisplay":null,"NewValue":"1","NewDisplay":"1"\},\{"ColumnName":"MyLinkedEntityId","OriginalValue":null,"OriginalDisplay":null,"NewValue":"1","NewDisplay":"1"\}] | Admin | 1 | [\{"EntityType":"MyEntity","IndexPropertyName":"MyEntityId","IndexPropertyValue":"1"\},\{"EntityType":"MyLinkedEntity","IndexPropertyName":"MyLinkedEntityId","IndexPropertyValue":"1"\}] | 1 | 1 |
| 2 | 0x000000000000082D | 2025-01-28 14:04:21.1660368 | Delete | [\{"ColumnName":"MyEntityId","OriginalValue":null,"OriginalDisplay":null,"NewValue":"1","NewDisplay":"1"\},\{"ColumnName":"MyLinkedEntityId","OriginalValue":null,"OriginalDisplay":null,"NewValue":"1","NewDisplay":"1"\}] | Admin | 1 | [\{"EntityType":"MyEntity","IndexPropertyName":"MyEntityId","IndexPropertyValue":"1"\},\{"EntityType":"MyLinkedEntity","IndexPropertyName":"MyLinkedEntityId","IndexPropertyValue":"1"\}] | 1 | 1 |

### One-To-Many
Given the following example :
```csharp title="MyEntity.cs"
[AuditInclude]
public class MyEntity : BaseEntity<int>
{
    public string AuditedProperty { get; set; }
    public ICollection<MyChildEntity> ChildEntities { get; set; } 
}
```
```csharp title="MyChildEntity.cs"
public class MyChildEntity : BaseEntity<int>
{
    public int MyEntityId { get; set; }
    public string ChildAuditedProperty { get; set; }
}
```

Follow the same steps as described into [previous chapter](#many-to-many) but refers to the `MyChildEntity` collection instead of a join entity collection.

### Many-To-One | One-To-One
By default, the audit changes already save the identifier value of the linked entity declared as Many-To-One or One-To-One relation.

## Configure Display Properties
:::warning
Only compatible for entities with [configured audit linked entities](#configure-audit-linked-entities) and for usage of historical entity display.
:::
### Many-To-Many | One-To-Many
:::info
Following code snippets will use **Many-To-Many** relationship example
:::
1. Add the attribute `[AuditLinkedEntity]` onto your dedicated audit table for your linked entity :
```csharp title="MyEntityMyLinkedEntityAudit.cs"
[AuditLinkedEntity(linkedEntityType: typeof(MyEntity), linkedEntityPropertyName: nameof(MyEntity.LinkedEntities))]
public class MyEntityMyLinkedEntityAudit : AuditEntity<MyEntityMyLinkedEntity>
{
}
```
- **linkedEntityType** : the type of entity linked to the audited entity type
- **linkedEntityPropertyName** : the property name that refers to the audited entity into the linked entity 
:::info
- In **One-To-Many** relationship, we refer the `linkedEntityPropertyName` to the **direct** reference collection property
- In **Many-To-Many** relationship, we refer the `linkedEntityPropertyName` to the **join** reference collection property
:::
:::tip
You can add multiple `[AuditLinkedEntity]` for each linked entity to the audited entity
:::

2. Add display properties that corresponds to the display value of the linked entities and fill them with the `FillSpecificProperties` overrided method :
```csharp title="MyEntityMyLinkedEntityAudit.cs"
[AuditLinkedEntity(linkedEntityType: typeof(MyEntity), linkedEntityPropertyName: nameof(MyEntity.LinkedEntities))]
public class MyEntityMyLinkedEntityAudit : AuditEntity<MyEntityMyLinkedEntity>
{
    [AuditLinkedEntityPropertyIdentifier(linkedEntityType: typeof(MyEntity))]
    public int MyEntityId { get; set; }

    [AuditLinkedEntityPropertyIdentifier(linkedEntityType: typeof(MyLinkedEntity))]
    public int MyLinkedEntityId { get; set; }

    public string MyEntityDisplay { get; set; }

    public string MyLinkedEntityDisplay { get; set; }

    protected override void FillSpecificProperties(MyEntityMyLinkedEntity entity)
    {
        this.MyEntityDisplay = entity.MyEntity.AuditedProperty;
        this.MyLinkedEntityDisplay = entity.MyLinkedEntity.LinkedAuditedProperty;
    }
}
```

3. Add attribute `[AuditLinkedEntityPropertyDisplay]` onto the target display property that corresponds to your linked entity type :
```csharp title="MyEntityMyLinkedEntityAudit.cs"
[AuditLinkedEntity(linkedEntityType: typeof(MyEntity), linkedEntityPropertyName: nameof(MyEntity.LinkedEntities))]
public class MyEntityMyLinkedEntityAudit : AuditEntity<MyEntityMyLinkedEntity>
{
    [AuditLinkedEntityPropertyIdentifier(linkedEntityType: typeof(MyEntity))]
    public int MyEntityId { get; set; }

    [AuditLinkedEntityPropertyIdentifier(linkedEntityType: typeof(MyLinkedEntity))]
    public int MyLinkedEntityId { get; set; }

    public string MyEntityDisplay { get; set; }

    [AuditLinkedEntityPropertyDisplay(linkedEntityType: typeof(MyEntity))]
    public string MyLinkedEntityDisplay { get; set; }

    protected override void FillSpecificProperties(MyEntityMyLinkedEntity entity)
    {
        this.MyEntityDisplay = entity.MyEntity.AuditedProperty;
        this.MyLinkedEntityDisplay = entity.MyLinkedEntity.LinkedAuditedProperty;
    }
}
```
:::info
Here, `MyLinkedEntityDisplay` will be considered as display value for the join relation of `MyEntity` with `MyLinkedEntity`.  

It means that when this linked entity audit will be retrieve to build the historical of `MyEntity`, the link display value to all `MyLinkedEntity` will be based on the `[AuditLinkedEntityPropertyDisplay]` attribute with corresponding linked entity type `MyEntity`.
:::
:::tip
You can add multiple `[AuditLinkedEntityPropertyIdentifier]` for a same display property but with different `linkedEntityType`.
:::

### Many-To-One | One-To-One
Given the following example :
```csharp title="MyEntity.cs"
[AuditInclude]
public class MyEntity : BaseEntity<int>
{
    public string AuditedProperty { get; set; }
    public MyLinkedEntity LinkedEntity { get; set; } 
    public int MyLinkedEntityId { get; set; }
}
```
```csharp title="MyLinkedEntity.cs"
public class MyLinkedEntity : BaseEntity<int>
{
    public string LinkedAuditedProperty { get; set; }
}
```

Into your entity dedicated audit class, add a display property for the linked entity with attribute `[AuditLinkedEntityProperty]` : 
```csharp title="MyEntityAudit.cs"
public class MyEntityAudit : AuditEntity<MyEntity>
{
    public string AuditedProperty { get; set; }

    [AuditLinkedEntityProperty(
        linkedEntityType: typeof(MyLinkedEntity),
        linkedEntityPropertyDisplay: nameof(MyLinkedEntity.LinkedAuditedProperty),
        entityReferencePropertyIdentifier: nameof(MyEntity.MyLinkedEntityId),
        entityPropertyName: nameof(MyEntity.LinkedEntity))]
    public string LinkedPropertyDisplay { get; set; }
}
```
- **linkedEntityType** : the linked entity type that refers to the property display
- **linkedEntityPropertyDisplay** : the linked entity property use for getting the display value 
- **entityReferencePropertyIdentifier** : the audited entity property identifier that make the link with the linked entity
- **entityPropertyName** : the audited entity property that refers to the linked entity

Your dedicated audit table will be like this :
| Id | RowVersion | AuditDate | AuditAction | AuditChanges | AuditUserLogin | EntityId | LinkedEntities | LinkedPropertyDisplay |
| -- | -- | -- | -- | -- | -- | -- | -- | -- |
| 1 | 0x000000000000082C | 2025-01-28 14:04:20.1660368 | Insert | [\{"ColumnName":"AuditedProperty","OriginalValue":null,"OriginalDisplay":null,"NewValue":"Something","NewDisplay":"Something"\},\{"ColumnName":"LinkedPropertyDisplay","OriginalValue":null,"OriginalDisplay":null,"NewValue":"1","NewDisplay":"LinkedEntity1"\}] | Admin | 1 | | LinkedEntity1 |
| 2 | 0x000000000000082D | 2025-01-28 14:04:21.1660368 | Update | [\{"ColumnName":"LinkedPropertyDisplay","OriginalValue":1,"OriginalDisplay":"LinkedEntity1","NewValue":"2","NewDisplay":"LinkedEntity2"\}] | Admin | 1 | | LinkedEntity2 |


## AuditLog : switch Id to longInt (Optional)
:::warning 
OBSOLETE
:::
If required you can switch the Id from int to longInt:
### Transform the entity
Update AuditLog.cs : use long in the inheritance IEntity and in the Id type
```csharp
    public class AuditLog : AuditEntity, IEntity<long>
    {
        /// <summary>
        /// Gets or sets the id.
        /// </summary>
        public long Id { get; set; }
    }
```

### Generate the migration
Add-Migration "AuditLongId" -Context "DataContext"

### Adapt the migration
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