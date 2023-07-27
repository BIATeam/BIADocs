---
layout: default
title: Role
parent: Right management
grand_parent: Developer guide
nav_order: 30
---

# Role
This file explains how user gain role and how it is transform in permission.

## User roles in team

## User roles for application

## Roles to permission

## Single or Multi Role Mode
### 3 ways to use the role in this framework:
* In the standard mode the user get always all the roles that he have for the selected Site.
* An other posibility is to give the possibility to the user to select only one role. In this case a combo appear at the left on the site selection to select the role he want.
* An other posibility is to give the possibility to the user to select several roles. In this case a multi select combo appear at the left on the site selection to select the roles he want.

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