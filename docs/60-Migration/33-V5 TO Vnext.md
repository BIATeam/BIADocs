---
sidebar_position: 1
---
# V5 to Vnext

## BIA Framework Migration
 
1. Delete from your Angular projects all **package-lock.json** and **node_modules** folder
2. Use the BIAToolKit to migrate the project : 
   * Run it automatically by clicking on **Migrate** button  
   **or**
   * Execute each step manually until step **3 - Apply Diff**
3. **Mind to check the output logs to check any errors or missing deleted files**
4. Manage the conflicts (two solutions) :
   * Merging rejected files
     * Execute step **4 - Merge Rejected** (already executed with automatic migration)
     * Search `<<<<<` in all files
     * Resolve the conflicts
   * Analyzing rejected files - **MANUAL MIGRATION ONLY**
     * Analyze all the `.rej` files (search "diff a/" in VS code)
     * Apply manually the changes into your files
   :::tip
   Use the [conflict resolution chapter](#conflict-resolution) to help you
   :::
5. For each Angular project, launch the **npm install** and **npm audit fix** command
6. Download the [migration script](./Scripts/V5_to_Vnext_Replacement.ps1)
   1. Change source path of the migration script to target your project root and your Angular project 
   2. Run it for each of your Angular project (change the Angular source path each time)
7. Apply other manual steps for [Front](#front-manual-steps) (for each Angular project) and [Back](#back-manual-steps)
8. Resolve missing and obsolete usings in back-end with BIAToolKit (step **6 - Resolve Usings**)
9. Resolve building issues into your Angular projects and back end
10. If all is ok, you can remove the `.rej` files. During the process they can be useful to resolve build problems
11. Execute the [database migration instructions](#database-migration)
12. For each Angular project, launch the `npm run clean` command
13. Clean back-end solution

## Conflict Resolution
### AuditFeature
Into `AuditTypeMapper` method, integrate your old switch case conditions into the new one :
``` csharp title="AuditFeature.cs (OLD)"
public override Type AuditTypeMapper(Type type)
{
   switch(type.Name)
   {
      case "MyEntity":
         return typeof(MyEntityAudit);
      default:
         return base.AuditTypeMapper(type);
   }
}
```
``` csharp title="AuditFeature.cs (NEW)"
public override Type AuditTypeMapper(Type type)
{
   return type.Name switch
   {
      // Your previous mapping here
      nameof(MyEntity) => typeof(MyEntityAudit),

      // BIAToolKit - Begin AuditTypeMapper
      // BIAToolKit - End AuditTypeMapper
      nameof(User) => typeof(UserAudit),
      _ => base.AuditTypeMapper(type),
   };
}
```

## Front Manual Steps
### Full code Index Component
For your full code `feature-index.component.html`, you will have to add into the `.ts` the following method :
``` typescript title="feature-index.component.ts"
onViewNameChange(viewName: string | null) {}
```

Or, you can simply remove from the `.html` the following binding : `(viewNameChange)="onViewNameChange($event)"`
### Team Configuration
:::tip
Automatically handled by migration script, for information purpose and manual adjustement only.
:::
From the file `all-environments.ts`, move the content of your `teams` configuration into back-end file `TeamConfig.cs` :
``` typescript title="all-environments.ts"
export const allEnvironments = {
  teams: [
    {
      teamTypeId: TeamTypeId.MyTeam,
      // Configuration to move below
      roleMode: RoleMode.AllRoles,
      inHeader: true,
      displayOne: false,
      displayAlways: false,
      teamSelectionCanBeEmpty: false,
      label: 'myTeam.headerLabel',
    },
  ]
}
```
``` csharp title="TeamConfig.cs"
public static class TeamConfig
{
    public static readonly ImmutableList<BiaTeamConfig<BaseEntityTeam>> Config = new ImmutableListBuilder<BiaTeamConfig<BaseEntityTeam>>()
    {
        new BiaTeamConfig<BaseEntityTeam>()
        {
            TeamTypeId = (int)TeamTypeId.MyTeam,
            RightPrefix = "MyTeam",
            AdminRoleIds = [(int)RoleId.MyTeamAdmin],
            TeamAutomaticSelectionMode = BIA.Net.Core.Common.Enum.TeamSelectionMode.None,
            // Configuration from TS
            RoleMode = BIA.Net.Core.Common.Enum.RoleMode.AllRoles,
            DisplayInHeader = true,
            DisplayOne = false,
            DisplayAlways = false,
            TeamSelectionCanBeEmpty = false
            Label = "myTeam.headerLabel",
        },
    }
}
```
Then, remove the `teams` from `all-environments.ts`

## Back Manual Steps
### Audit Entities
For all your previous audit entities inherited from `AuditEntity` :
- inherits from `AuditKeyedEntity<TEntity, TEntityKey, TAuditKey>` for audited entities with single PK
- inherits from `AuditEntity<TEntity, TAuditKey>` for audited join entities with composite PK
:::tip
See [Audit documentation](../40-DeveloperGuide/80-Audit.md#dedicated-audit-table) for dedicated audit tables.
:::

## Database Migration
You must create a new database migration in order to update the audit entities and the `AuditLogs` table scheme :
1. `add-migration MigrationV6_AuditEntitiesSchemeUpdate -c datacontext`
2. `update-database -context datacontext`