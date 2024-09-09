---
sidebar_position: 1
---

# Role
This file explains how user gain role and how it is transform in permission.

## User roles in team
With the user interface of the application authorized users can navigate on the team CRUD.
By clicking on a team they access to the member CRUD. And they can add member with roles on teams.

When a user is connected to the application he can change of current team in the upper right combo.
He gains the roles associate to the user in the current team (only the selected one in Single or Multi Role).
Warning : You can have several type of team, so you can have several combo in header. In this case you have several current teams (one by type).

When the user navigate in the application one of the current team can be change by code in Angular Front app, if required.
This action is done by the function changeCurrentTeamId of AuthService.
Example in the service of a Team CRUD:
```js
    public set currentCrudItemId(id: any) {
        if (this._currentCrudItemId !== id)
        {
            this._currentCrudItemId = id;
            this.authService.changeCurrentTeamId(TeamTypeId.AircraftMaintenanceCompany, id);
        }
        this.load( id );
    }
```

## User roles for application
With the user interface of the application authorized users can navigate on the user CRUD.
By clicking on a user you can add roles on the users.

Those roles do not depend on teams and are available for the all the navigation in the apps. 

## Roles to permission
Role are translated in permission conform to the file bianetconfig.json in the table Permissions
```json
    "Permissions": [
      {
        "Names": [ "Admin" ],
        "Roles": [ "Admin" ]
      },
      {
        "Names": [ "Site_Admin" ],
        "Roles": [ "Site_Admin" ]
      },
      ... 
    ]
```
The permission are send in the jwt token and can be use in the Back and the Front code.
### Permission in Front
In the front application you should manage access to action buttons with the function this.authService.hasPermission
```js
  protected setPermissions() {
    this.canEdit = this.authService.hasPermission(Permission.Site_Update);
    this.canDelete = this.authService.hasPermission(Permission.Site_Delete);
    this.canAdd = this.authService.hasPermission(Permission.Site_Create);
    // Custo for teams
    this.canManageMembers = this.authService.hasPermission(Permission.Site_Member_List_Access);
  }
```

The access to the screens are filtered with the data.permission attribute in the Routes definition of the module.
```js
export let ROUTES: Routes = [
  {
    path: '',
    data: {
      breadcrumb: null,
      permission: Permission.Site_List_Access,
      InjectComponent: SitesIndexComponent
    },
```

### Permission in Back
In the controller decorate the function with the required permission
```csharp
        [Authorize(Roles = Rights.Notifications.ListAccess)]
        public async Task<IActionResult> GetUnreadIds()
```
The permission can be use to filter service. See [Filter data](./40-FilterData.md)

## Highlight on Single or Multi Role Mode
### 3 ways to use the role in this framework:
* In the standard mode the user get always all the roles that he have for the selected Site.
* An other possibility is to give the possibility to the user to select only one role. In this case a combo appear at the left on the site selection to select the role he want.
* An other possibility is to give the possibility to the user to select several roles. In this case a multi select combo appear at the left on the site selection to select the roles he want.

### Select of the Single Role Mode:
In file ...\Angular\src\environments\all-environment.ts
Select role mode you want (RoleMode.AllRoles, RoleMode.MultiRoles or RoleMode.SingleRole)

```JSon
    teams: [
        {teamTypeId: TeamTypeId.Site, roleMode: RoleMode.AllRoles, inHeader: true},
        {teamTypeId: TeamTypeId.AircraftMaintenanceCompany, roleMode: RoleMode.MultiRoles, inHeader: true},
        {teamTypeId: TeamTypeId.MaintenanceTeam, roleMode: RoleMode.SingleRole, inHeader: true},
    ],
```

If you are in RoleMode.AllRoles and you manage the change of team by navigation in the application, you do no need to display the combos (select team and select role) in header.

=> you can set
```JSon
 inHeader: false
```