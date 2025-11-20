---
sidebar_position: 1
---

import CheckItem from '@site/src/components/CheckItem';

# V5 to Vnext

## Prerequisites 
<CheckItem>Upgrade to compatible versions of **node.js** and **npm** for Angular V20 ([Setup Environment Angular](../10-Introduction/20-SetupEnvironment/SetupEnvironmentAngular.md#nodejs))</CheckItem>
<CheckItem>Run `npm i -g @angular/cli@20`</CheckItem>
<CheckItem>⚡**Create a new feature branch for the migration**</CheckItem>

## Angular V20 Migration
### Editor's migration guides
:::info
- [Angular v19 -> v20](https://angular.dev/update-guide?v=19.0-20.0&l=3)
- [NgRx v20](https://ngrx.io/guide/migration/v20)
- [PrimeNG v20](https://primeng.org/migration/v20)
- [ngx-translate v16 -> v17](https://ngx-translate.org/getting-started/migration-guide/)
:::

### Deprecation of Angular's animations package
:::warning
Angular has deprecated the animations package to use the native CSS instead.  
Your project can lead to some warning issues when linting.  

To fix them, follow the [official migration documentation](https://angular.dev/guide/animations/migration)
:::

### Manual migration instructions
For each Angular project :
<CheckItem indent="1">run `ng update @angular/core@20 @angular/cli@20`</CheckItem>
:::info
1. Decline `use-application-builder` migration
2. Decline `control-flow-migration` migration
3. **Accept** `router-current-navigation` migration
:::
<CheckItem indent="1">⚡**COMMIT**</CheckItem>
<CheckItem indent="1">run `ng update @ngrx/store@20.0.0`</CheckItem>
<CheckItem indent="1">⚡**COMMIT**</CheckItem>




## BIA Framework Migration
<CheckItem>Delete from your Angular projects all **package-lock.json** and **node_modules** folder</CheckItem>
<CheckItem>Use the BIAToolKit to migrate the project</CheckItem>
:::info 
Run it automatically by clicking on **Migrate** button  
**or**  
Execute each step manually until step **3 - Apply Diff**
:::
:::warning
**Mind to check the output logs to check any errors or missing deleted files**
:::
<CheckItem>Manage the conflicts</CheckItem>
:::info
- **SOLUTION 1** : Merging rejected files
<CheckItem indent="1">execute step **4 - Merge Rejected** (already executed with automatic migration)</CheckItem>
<CheckItem indent="1">resolve the files marked as conflicts in your favorite IDE or merge editor</CheckItem>

- **SOLUTION 2** : Analyzing rejected files - **MANUAL MIGRATION ONLY**
<CheckItem indent="1">analyze all the `.rej` files (search "diff a/" in VS code)</CheckItem>
<CheckItem indent="1">apply manually the changes into your files</CheckItem>
:::
:::tip
Use the [conflict resolution chapter](#conflict-resolution) to help you
:::
<CheckItem>⚡**COMMIT**</CheckItem>
<br/>

For each Angular project :
<CheckItem indent="1">run `npm install`</CheckItem>
<CheckItem indent="1">run `npm audit fix`</CheckItem>
<CheckItem>⚡**COMMIT**</CheckItem>

Download the [migration script](./Scripts/V5_to_Vnext_Replacement.ps1) ([.txt - Save link as](./Scripts/V5_to_Vnext_Replacement.txt)), then :
<CheckItem indent="1">change source path of the migration script to target your project root and your Angular project</CheckItem>
<CheckItem indent="1">run it for each of your Angular project (change the Angular source path each time)</CheckItem>
<CheckItem>⚡**COMMIT**</CheckItem>

For each Angular project :
<CheckItem indent="1">run `ng generate @angular/core:control-flow`</CheckItem>
:::info
   1. validate current path as target path
   2. accept reformat templates option
:::
<CheckItem indent="1">run `ng generate @angular/core:cleanup-unused-imports`</CheckItem>
<CheckItem indent="1">Download the [cleanup standalone imports script](./Scripts/cleanup-standalone-imports.ps1) ([.txt - Save link as](./Scripts/cleanup-standalone-imports.txt)) :</CheckItem>
<CheckItem indent="2">Change `$RootPath` value to your Angular project</CheckItem>
<CheckItem indent="2">Run the script</CheckItem>
:::warning
If some warning about deprecation of `NgIf`, `NgFor` or `NgSwitch` are printed from the final linting, it means that the execution of `ng generate @angular/core:control-flow` has ignored the migration for concerned file due to some safety constraints.  

**You have to manually migrate to control flow instructions the identified files ([Angular Documentation](https://angular.dev/guide/templates/control-flow))**
:::
<CheckItem>⚡**COMMIT**</CheckItem>
<br/>

<CheckItem>For each Angular project, apply manual steps for [Front](#front-manual-steps)</CheckItem>
<CheckItem>Apply  manual steps for [Back](#back-manual-steps)</CheckItem>
<CheckItem>⚡**COMMIT**</CheckItem>
<br/>

<CheckItem>Resolve missing and obsolete usings in back-end with BIAToolKit (step **6 - Resolve Usings**)</CheckItem>
<CheckItem>Resolve building issues into Back</CheckItem>
<CheckItem>Resolve building issues into your Angular projects</CheckItem>
:::tip
For manual management of conflitcs case : you can remove the `.rej` files
:::
<CheckItem>⚡**COMMIT**</CheckItem>
<br/>

<CheckItem>Execute the [database migration instructions](#database-migration)</CheckItem>
<CheckItem>⚡**COMMIT**</CheckItem>
<br/>

<CheckItem>For each Angular project, launch the `npm run clean` command</CheckItem>
<CheckItem>Clean back-end solution</CheckItem>
<CheckItem>⚡**COMMIT**</CheckItem>

## Conflict Resolution
### all-environments.ts
Keep all your `teams` definition, there will be used by the migration script for the [Team Configuration step](#team-configuration)

### AuditFeature.cs
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

### useRefreshAtLanguageChange
In previous version, you'll have to use `useRefreshAtLanguageChange` property defined into your index components, usually to handle changes of current culture to refresh your data by calling `onLoadLazy` :
``` typescript title="my-features-index.component.ts"
ngOnInit(): void {
   super.ngOnInit();

   if (this.useRefreshAtLanguageChange) {
   this.sub.add(
      this.biaTranslationService.currentCulture$
         .pipe(skip(1))
         .subscribe(() => {
         this.onLoadLazy(this.crudItemListComponent.getLazyLoadMetadata());
      })
   );
   }
}
```

By now, this refresh is automatically handled into the `CrudItemsIndexCompoent` by using the property `useRefreshAtLanguageChange` from the `crudConfiguration`.  
So, you can remove from your index component the handler of `this.biaTranslationService.currentCulture$` to call `onLoadLazy`, and set into your feature constants the `useRefreshAtLanguageChange` to `true` :
``` typescript title="my-feature.constants.ts"
export const announcementCRUDConfiguration: CrudConfig<MyFeature> =
  new CrudConfig({
    // [...]
    useRefreshAtLanguageChange: true,
  });
```

For all cases using the previous `useRefreshAtLanguageChange` from `CrudItemIndexComponent`, simply use now the same property from the `crudConfiguration`.


## Back Manual Steps
### Audit Entities
For all your previous audit entities inherited from `AuditEntity` :
- inherits from `AuditKeyedEntity<TEntity, TEntityKey, TAuditKey>` for audited entities with single PK
- inherits from `AuditEntity<TEntity, TAuditKey>` for audited join entities with composite PK
:::tip
See [Audit documentation](../40-DeveloperGuide/80-Audit.md#dedicated-audit-table) for dedicated audit tables.
:::

## Database Migration
You must create a new database migration in order to apply framework changes to your database scheme :
1. `add-migration MigrationBiaFrameworkV6 -c datacontext`
2. `update-database -context datacontext`