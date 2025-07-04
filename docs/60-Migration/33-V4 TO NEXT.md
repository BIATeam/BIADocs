---
sidebar_position: 1
---
# V4 to NEXT

## Standalone Components Migration
1. Open a terminal into your angular root project
2. Run command `ng g @angular/core:standalone`
   1. Select **Convert standalone**
   2. Choose current root path of your project and validate
3. Run command `ng g @angular/core:standalone` again
   1. Select **Remove modules**
   2. Choose current root path of your project and validate
4. Commit the changes

## Angular 19 Migration

### Editor's migration guides
- [Angular v17 -> v18](https://angular.dev/update-guide?v=17.0-18.0&l=3)
- [Angular v18 -> v19](https://angular.dev/update-guide?v=18.0-19.0&l=3)
- [NgRx v18](https://ngrx.io/guide/migration/v18)
- [NgRx v19](https://ngrx.io/guide/migration/v19)
- [PrimeNG v18+](https://primeng.org/guides/migration)
- [Keycloak Angular v19](https://github.com/mauriciovigolo/keycloak-angular/blob/main/docs/migration-guides/v19.md)

### Angular CDK (v16 -> v17)
1. Open a terminal into your angular root project
2. Run command `ng update @angular/cdk@17`, you'll have the following automatic migrations :
   1. From **@angular/cdk@18**
      1. Updates the Angular CDK to v17
3. Commit the changes
### Angular Core (v17 -> v18)
4. Run command `ng update @angular/core@18 @angular/cli@18 @angular-eslint/schematics@18`, you'll have the following automatic migrations :
   1. From **@angular-eslint/schematics@18**
      1. Updates @angular-eslint to v18.2
   2. From **@angular/cli**
      1. Migrate application projects to the new build system : **you'll have to accept the migration action `use-application-builder`**
   3. From **@angular/core**
      1. Replace deprecated HTTP related modules with provider functions
      2. Updates calls to afterRender with an explicit phase to the new API
5. **Commit** the changes
### Angular Packages (v17 -> v18)
6. Run command `ng update @angular/cdk@18 @ngrx/store@18 @ngrx/store-devtools@18 keycloak-angular@16 primeng@18`, you'll have the following automatic migrations :
   1. From **@angular/cdk@18**
      1. Updates the Angular CDK to v18
   2. From **@ngrx/effects**
      1. As of NgRx v18, the `concatLatestFrom` import has been removed from `@ngrx/effects` in favor of the `@ngrx/operators` package
   3. From **@ngrx/store**
      1. As of NgRx v18, the `TypedAction` has been removed in favor of `Action`
7. **Commit** the changes
### Angular Core + Packages (v18 -> v19)
8. Run command `ng update @angular/core@19 @angular/cli@19 @angular-eslint/schematics@19 @angular/cdk@19 @ngrx/store@19 @ngrx/store-devtools@19 keycloak-angular@19 primeng@19`, you'll have the following automatic migrations :
   1. From **@angular/cli**
      1. Update '@angular/ssr' import paths to use the new '/node' entry point when 'CommonEngine' is detected
      2. Update the workspace configuration by replacing deprecated options in 'angular.json' for compatibility with the latest Angular CLI changes
      3. Migrate application projects to the new build system : **you'll have to ignore the migration action `use-application-builder`**
   2. From **@angular/cdk@19**
      1. Updates the Angular CDK to v19
   3. From **@angular/core**
      1. Updates non-standalone Directives, Component and Pipes to 'standalone:false' and removes 'standalone:true' from those who are standalone
      2. Updates ExperimentalPendingTasks to PendingTasks
      3. Replaces `APP_INITIALIZER`, `ENVIRONMENT_INITIALIZER` & `PLATFORM_INITIALIZER` respectively with `provideAppInitializer`, `provideEnvironmentInitializer` & `providePlatformInitializer` : **you'll have to accept the migration action `provide-initialize`**
   4. From **@ngrx/effects**
      1. As of NgRx v18, the `concatLatestFrom` import has been removed from `@ngrx/effects` in favor of the `@ngrx/operators` package
   5. From **@ngrx/store**
      1. As of NgRx v18, the `TypedAction` has been removed in favor of `Action`
9.  **Commit** the changes

## AUTOMATIC MIGRATION
 
1. Use the BIAToolKit to migrate the project
2. Delete all **package-lock.json** and **node_modules** folder

3. Manage the conflicts (2 solutions)
   1. In BIAToolKit click on "4 - merge Rejected" and search `<<<<<` in all files.  
    * Resolve the conflicts manually.
   2. Analyze the .rej file (search "diff a/" in VS code) that have been created in your project folder
     * Apply manually the change.

4. Download the [migration script](./Scripts/V4_to_VNEXT_Replacement.ps1) and the [standalone catch up script](./Scripts/standalone-catch-up.js) into the same directory
5. Change source path of the migration script and run it

6. Apply other manual step (describe below) at the end if all is ok, you can remove the .rej files (during the process they can be useful to resolve build problems)

7. Resolve missing and obsolete usings with BIAToolKit

8. Launch the command **npm install** and the command **npm audit fix**

## MANUAL STEPS
### FRONT
1. Remove **node_modules** directory from your project, then run `npm i` command
2. Replace `HttpClientModule` import by `provideHttpClient(withInterceptorsFromDi())` into the providers :
``` typescript title="Before" 
import { HttpClientModule } from '@angular/common/http';

@NgModule({
   imports: [
      HttpClientModule
   ]
})
```
``` typescript title="After" 
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';

@NgModule({
   providers: [
      provideHttpClient(withInterceptorsFromDi())
   ]
})
```
3. Replace all `@Output` properties with native event names such as `cancel`, `click` by another names (ex: `cancelled`, `clicked`)
4. Remove `Time` usage from your code
5. Adapt the usage of `<p-tabs>` migrated from `<p-tabView>` :
   1. Add `<p-tablist>` inside and under `<p-tabs>`
   2. For each existing `<p-tabpanel>`, add a `<p-tab>` inside `<p-tablist>` with an incremental numeric property `value`, with the inner content of previous `header` property of the `<p-tabpanel>` or of the `<ng-template pTemplate="header">` content
   3. Replace for each existing `<p-tabpanel>` property `header` by `value` with corresponding value of the added `<p-tab>`
   4. Add into the `<p-tabs>` a property `value` with the same identifier as your target tab to set as active by default
``` html title="Before" 
<p-tabView>
   <p-tabPanel *ngFor="let tab of tabs" header="tab.title">
      {{ tab.content }}
   </p-tabPanel>
</p-tabView>

<p-tabView>
   <p-tabPanel *ngFor="let tab of tabs">
      <ng-template pTemplate="header">
         {{ tab.title }}
      </ng-template>
      {{ tab.content }}
   </p-tabPanel>
</p-tabView>
```
``` html title="After" 
<p-tabs [value]="0">
   <p-tablist>
      @for (tab of tabs; track $index) {
        <p-tab [value]="$index">
          {{ tab.title }}
        </p-tab>
      }
   </p-tablist>
   @for (tab of tabs; track $index) {
      <p-tabpanel [value]="$index">
         {{ tab.content }}
      </p-tabpanel>
   }
</p-tabs>
```
6. Fix the automatic replacements of `<p-floatlabel>` to the correct HTML tag if any
7. Fix the automatic replacements of `<p-fluid>` to the correct HTML tag if any
8. For each `<p-checkbox>` with label, add into `div` parent container the classes `flex items-center`
``` html title="Before" 
<div>
   <p-checkbox></p-checkbox>
   <label>Something</label>
</div>
```
``` html title="After" 
<div class="flex items-center">
   <p-checkbox></p-checkbox>
   <label>Something</label>
</div>
```
9.  The eslint plugin `eqeqeq` (forcing usage of === instead of ==) should be activated after migration. You can keep it activated and fix all lint errors or you can deactivate it in the .eslintrc file of your project by changing every line where eqeqeq appears by :
```json
"eqeqeq": "off"
```
10. Moving advanced filters to the right :
    1. Move advanced filter html after table in index.component
    2. Move from table-header to table-controller html :
``` ts
[showBtnFilter]="true"
[showFilter]="showAdvancedFilter"
[hasFilter]="hasAdvancedFilter"
(openFilter)="onOpenFilter()"
```
11. Replace into your .scss files the usage of `@import` by `@use` and add the import file name as suffix of the concerned properties 
``` css title="Before" 
@import '../theme'

button {
   color: $button-color /* From theme */
}
```
``` css title="After" 
@use '../theme'

button {
   color: theme.$button-color
}
```
### BACK
#### Database migration
1. Add a new migration **CreateUserDefaultTeamsTable**
2. Edit the generated migration and update the `Up()` and `Down()` methods with following : 
   ``` csharp
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "UserDefaultTeams",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    TeamId = table.Column<int>(type: "int", nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserDefaultTeams", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserDefaultTeams_Teams_TeamId",
                        column: x => x.TeamId,
                        principalTable: "Teams",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserDefaultTeams_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserDefaultTeams_TeamId",
                table: "UserDefaultTeams",
                column: "TeamId");

            migrationBuilder.CreateIndex(
                name: "IX_UserDefaultTeams_UserId_TeamId",
                table: "UserDefaultTeams",
                columns: new[] { "UserId", "TeamId" },
                unique: true);

            migrationBuilder.Sql(@"
                INSERT INTO UserDefaultTeams (UserId, TeamId)
                SELECT UserId, TeamId
                FROM Members
                WHERE IsDefault = 1;
            ");

            migrationBuilder.DropColumn(
                name: "IsDefault",
                table: "Members");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsDefault",
                table: "Members",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.Sql(@"
                INSERT INTO Members (UserId, TeamId, IsDefault)
                SELECT UserId, TeamId, 1
                FROM UserDefaultTeams;
            ");

            migrationBuilder.DropTable(
                name: "UserDefaultTeams");
        }
   ```
3. Update database