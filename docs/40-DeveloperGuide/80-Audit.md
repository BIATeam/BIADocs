---
sidebar_position: 80
---

# Audit
This file explains how to activate/deactivate the audit feature and how to customize it.

## Prerequisite
The audit feature is actively using the **Audit.NET** library
* [Audit.NET github site](https://github.com/thepirat000/Audit.NET)
* [Audit.NET documentation](https://github.com/thepirat000/Audit.NET/blob/master/README.md)
* [Audit.EntityFramework documentation](https://github.com/thepirat000/Audit.NET/blob/master/src/Audit.EntityFramework/README.md)
* [Audit.NET.SqlServer documentation](https://github.com/thepirat000/Audit.NET/blob/master/src/Audit.NET.SqlServer/README.md)

## Overview
The audit feature, by default, stores the modifications done on entity objects in a dedicated **Events** table of the default database.  

BIA Framework will save by default all changes occurs to the `Users` entities.

## Activation/Deactivation
To activate/deactivate the feature modify the "IsActive" property in the following part of the bianetconfig file:
``` json
  "AuditConfiguration": {
    "IsActive": true,
    "ConnectionStringName": "ProjectDatabase"      
  }
```      

## Configuration
This chapter will concern new entities to audit.
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
| AuditId | Table | PrimaryKey | AuditDate | AuditAction | AuditChanges | AuditUserLogin |
| -- | -- | -- | -- | -- | -- | -- |
| 1 | MyEntities | \{"Id":1\} | 2025-01-28 14:04:20.1660368 | Insert | \{"Id":1,"AuditedProperty":"Something"\} | Admin |
| 2 | MyEntities | \{"Id":1\} | 2025-01-28 14:05:20.1660368 | Update | [\{"ColumnName":"AuditedProperty","OriginalValue":"Something","NewValue":"Another thing"\}] | Admin |
| 3 | MyEntities | \{"Id":1\} | 2025-01-28 14:06:20.1660368 | Delete | \{"Id":1,"AuditedProperty":"Another thing"\} | Admin |

- **AuditId** : the Id of the audit log
- **Table** : table of the audited entity
- **PrimaryKey** : JSON of all PK of the audited entity
- **AuditDate** : date of the audit log
- **AuditAction** : action of the audit log : `Insert` | `Update` | `Delete`
- **AuditChanges** : changes of the audit log
  - JSON of the audited entity in case of `Insert` or `Delete` action
  - For `Update` action, JSON of all the audited changes of the entity with `ColumnName`, `OriginalValue` and `NewValue`
- **AuditUserLogin** : user login that triggered the entity audit log

#### Dedicated Audit table
The usage of a dedicated table simplify the history of change in a user interface, and mandatory when displaying the historical of an entity ([see documentation](./20-CRUD/30-Historical.md)).

1. Create your own audit entity into same namespace as your entity, and inherits from `AuditKeyedEntity<TEntity, TEntityKey, TAuditKey>` class where `TEntity` is your audited entity class, `TEntityKey` is your audited entity key type, `TAuditKey` is the key type of the audit :
```csharp title="MyEntityAudit.cs"
public class MyEntityAudit : AuditKeyedEntity<MyEntity, int, int>
{
}
```
:::tip
For a join entity audit without unique primary key, inherits from `AuditKeyedEntity<TEntity, TAuditKey>`
:::
2. Add the same properties as your audited entity to store the values into dedicated columns :
```csharp title="MyEntityAudit.cs"
public class MyEntityAudit : AuditKeyedEntity<MyEntity, int, int>
{
    public string AuditedProperty { get; set; }
}
```
3. You can add custom properties to fill with the audited entity values by overidding the `FillSpecificProperties` method :
```csharp title="MyEntityAudit.cs"
public class MyEntityAudit : AuditKeyedEntity<MyEntity, int, int>
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
    public override void CreateModel(ModelBuilder modelBuilder)
    {
        base.CreateModel(modelBuilder);
        this.CreateUserAuditModel<UserAudit, User>(modelBuilder);

        // Add here the project specific audit model creation.
        CreateMyEntityAuditModel(modelBuilder);
    }

    private static void CreateMyEntityAuditModel(ModelBuilder modelBuilder)
    {
        // Configure the audit model
    }
}
```

Your dedicated audit table will following this kind of scheme :
| AuditId | AuditDate | AuditAction | AuditChanges | AuditUserLogin | Id | AuditedProperty | CustomProperty |
| -- | -- | -- | -- | -- | -- | -- | -- |
| 1 | 2025-01-28 14:04:20.1660368 | Insert | [\{"ColumnName":"AuditedProperty","OriginalValue":null,"OriginalDisplay":null,"NewValue":"Something","NewDisplay":"Something"\}] | Admin | 1 | Something | 2 |
| 2 | 2025-01-28 14:04:21.1660368 | Update | [\{"ColumnName":"AuditedProperty","OriginalValue":"Something","OriginalDisplay":Something,"NewValue":"Another thing","NewDisplay":"Another thing"\}] | Admin | 1 | Another thing | 2 |
| 3 | 2025-01-28 14:04:22.1660368 | Delete | [\{"ColumnName":"AuditedProperty","OriginalValue":"Another thing","OriginalDisplay":"Another thing","NewValue":null,"NewDisplay":null\}] | Admin | 1 | Another thing | 2 |

- **AuditId** : the Id of the audit log
- **AuditDate** : date of the audit log
- **AuditAction** : action of the audit log : `Insert` | `Update` | `Delete`
- **AuditChanges** : changes of the audit log
  - JSON of all the audited changes of the entity with `ColumnName`, `OriginalValue` and `NewValue`. `OriginalDisplay` and `NewDisplay` are the specific displayed values of the changes (by default, value to string)
- **AuditUserLogin** : user login that triggered the entity audit log
- **Id** : identifier of the audited entity
- **AuditedProperty** : according to the current example, corresponds to the `AuditedProperty` value of the audited entity
- **CustomProperty** : according to the current example, corresponds to the `CustomProperty` value of the audited entity

:::tip
You can automatically generate these files by using the **BIAToolKit DTO Generator** with projects from **BIAFramework V6** with `Use dedicated audit` option enabled. It will generate the file's content of the [Configure Display Properties chapter](#configure-display-properties) too.
:::

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
public class MyEntityMyLinkedEntityAudit : AuditEntity<MyEntityMyLinkedEntity, int>
{
}
```

3. Add the primary key index properties into your dedicated join audit entity :
```csharp title="MyEntityMyLinkedEntityAudit.cs"
public class MyEntityMyLinkedEntityAudit : AuditEntity<MyEntityMyLinkedEntity, int>
{
    public int MyEntityId { get; set; }

    public int MyLinkedEntityId { get; set; }
}
```

The dedicated audit table will be like this :
| AuditId | AuditDate | AuditAction | AuditChanges | AuditUserLogin | MyEntityId | MyLinkedEntityId |
| -- | -- | -- | -- | -- | -- | -- |
| 1 | 2025-01-28 14:04:20.1660368 | Insert | [\{"ColumnName":"MyEntityId","OriginalValue":null,"OriginalDisplay":null,"NewValue":1,"NewDisplay":"1"\},\{"ColumnName":"MyLinkedEntityId","OriginalValue":null,"OriginalDisplay":null,"NewValue":1,"NewDisplay":"1"\}] | Admin | 1 | 1 |
| 2 | 2025-01-28 14:04:21.1660368 | Delete | [\{"ColumnName":"MyEntityId","OriginalValue":1,"OriginalDisplay":"1","NewValue":null,"NewDisplay":null\},\{"ColumnName":"MyLinkedEntityId","OriginalValue":1,"OriginalDisplay":"1","NewValue":null,"NewDisplay":null\}] | Admin | 1 | 1 |

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

According to the [previous chapter](#many-to-many), but using the `MyChildEntity` collection instead of a join entity collection, your dedicated audit entity must look to this :
```csharp title="MyChildEntityAudit.cs"
public class MyChildEntityAudit : AuditKeyedEntity<MyChildEntity, int, int> 
// Not join entity, so inherits from AuditKeyedEntity<TEntity, TEntityKey, TAuditKey>
{
    public int MyEntityId { get; set; }

    public string ChildAuditedProperty { get; set; }
}
```

The dedicated audit table will be like this :
| AuditId | AuditDate | AuditAction | AuditChanges | AuditUserLogin | MyEntityId | ChildAuditedProperty |
| -- | -- | -- | -- | -- | -- | -- |
| 1 | 2025-01-28 14:04:20.1660368 | Insert | [\{"ColumnName":"MyEntityId","OriginalValue":null,"OriginalDisplay":null,"NewValue":1,"NewDisplay":"1"\},\{"ColumnName":"ChildAuditedProperty","OriginalValue":null,"OriginalDisplay":null,"NewValue":"Something","NewDisplay":"Something"\}] | Admin | 1 | Something |
| 2 | 2025-01-28 14:04:21.1660368 | Delete | [\{"ColumnName":"MyEntityId","OriginalValue":1,"OriginalDisplay":"1","NewValue":null,"NewDisplay":null\},\{"ColumnName":"ChildAuditedProperty","OriginalValue":"Something","OriginalDisplay":"Something","NewValue":null,"NewDisplay":null\}] | Admin | 1 | Something |

### Many-To-One | One-To-One
By default, the audit changes already save the identifier value of the linked entity declared as Many-To-One or One-To-One relation.

## Configure Display Properties
:::warning
Only compatible for entities with [configured audit linked entities](#configure-audit-linked-entities) and for usage of historical entity display ([see documentation](./20-CRUD/30-Historical.md)).
:::

First, you must create an audit mapper for your audit entity into your domain entity mapper folder :
``` csharp title="MyEntityAuditMapper"
public class MyEntityAuditMapper : AuditMapper<MyEntity>
{
    public MyEntityAuditMapper()
    {
        // The constructor will be completed in the next chapters
    }
}
```

Then, inject it as `Singleton` into the `IocContainer` crosscutting class :
``` csharp title="IocContainer"
public static class IocContainer
{
    private static void ConfigureDomainContainer(IServiceCollection collection)
    {
        // [...]

        // Inject audit mappers
        collection.AddSingleton<IAuditMapper, MyEntityAuditMapper>();
    }
}
```

:::tip
Automatically generated by using the **BIAToolKit DTO Generator** with projects from **BIAFramework V6** with `Use dedicated audit` option enabled. It will generate the file's content of the [Dedicated Audit Table chapter](#dedicated-audit-table) too.
:::

### Many-To-Many | One-To-Many
:::info
Following code snippets will use **Many-To-Many** relationship example as seen in [previous chapter](#many-to-many).
:::

Add into your join entity audit a display property for the linked entity and set the value into the overrided method `FillSpecificProperties` :
```csharp title="MyEntityMyLinkedEntityAudit.cs"
public class MyEntityMyLinkedEntityAudit : AuditEntity<MyEntityMyLinkedEntity, int>
{
    public int MyEntityId { get; set; }

    public int MyLinkedEntityId { get; set; }

    public string MyLinkedEntityDisplay { get; set; }

    protected override void FillSpecificProperties(MyEntityMyLinkedEntity entity)
    {
        this.MyLinkedEntityDisplay = entity.MyLinkedEntity.LinkedAuditedProperty;
    }
}
```

Then, complete the `LinkedAuditMappers` collection of the `MyEntityAuditMapper` and configure it like this :
``` csharp title="MyEntityAuditMapper"
public class MyEntityAuditMapper : AuditMapper<MyEntity>
{
    public MyEntityAuditMapper()
    {
        this.LinkedAuditMappers =
        [
            new LinkedAuditMapper<MyEntity, MyEntityMyLinkedEntityAudit>
            {
                EntityProperty = myEntity => myEntity.LinkedEntities,
                LinkedAuditEntityIdentifierProperty = audit => audit.MyEntityId,
                LinkedAuditEntityDisplayProperty = audit => audit.MyLinkedEntityDisplay,
            },
        ];
    }
}
```
:::info
For the `LinkedEntities` property of my audited entity `MyEntity`, the corresponding display value will be mapped to the `MyLinkedEntityDisplay` property of the linked audit `MyEntityMyLinkedEntityAudit`, using the property `MyEntityId` from `MyEntityMyLinkedEntityAudit` to link the current `MyEntity`.
:::

### Many-To-One | One-To-One
Given the following example :
```csharp title="MyEntity.cs"
[AuditInclude]
public class MyEntity : BaseEntity<int>
{
    public MyLinkedEntity LinkedEntity { get; set; } 
    public int MyLinkedEntityId { get; set; }
}
```
```csharp title="MyLinkedEntity.cs"
public class MyLinkedEntity : BaseEntity<int>
{
    public string Name { get; set; }
}
```

Complete the `AuditPropertyMappers` collection of the `MyEntityAuditMapper` and configure it like this :
``` csharp title="MyEntityAuditMapper"
public class MyEntityAuditMapper : AuditMapper<MyEntity>
{
    public MyEntityAuditMapper()
    {
        this.AuditPropertyMappers =
        [
            new AuditPropertyMapper<MyEntity, MyLinkedEntity>
            {
                EntityProperty = myEntity => myEntity.LinkedEntity,
                EntityPropertyIdentifier = myEntity => myEntity.LinkedEntityId,
                LinkedEntityPropertyDisplay = myLinkedEntity => myLinkedEntity.Name,
            },
        ];
    }
}
```
:::info
For the `LinkedEntity` property of my audited entity `MyEntity`, the corresponding display value will be mapped to the `Name` property of the linked entity `MyLinkedEntity`, using the property `LinkedEntityId` from `MyEntity` to link with the target `MyLinkedEntity`.
:::

Your dedicated audit table will be like this :
| AuditId | RowVersion | AuditDate | AuditAction | AuditChanges | AuditUserLogin | Id |
| -- | -- | -- | -- | -- | -- | -- |
| 1 | 0x000000000000082C | 2025-01-28 14:04:20.1660368 | Insert | [\{"ColumnName":"LinkedEntityId","OriginalValue":null,"OriginalDisplay":null,"NewValue":1,"NewDisplay":"Name1"\}] | Admin | 1 |
| 2 | 0x000000000000082D | 2025-01-28 14:04:21.1660368 | Update | [\{"ColumnName":"LinkedEntityId","OriginalValue":1,"OriginalDisplay":"Name1","NewValue":"2","NewDisplay":"Name2"\}] | Admin | 1 |