---
layout: default
title: Teams
parent: Right management
grand_parent: Developer guide
nav_order: 20
---

# Teams
This file explains what teams are and how to add new type of team to your project.

## What is a team?
A team is an item on which we give roles to users.
Therefore, when you add a new type of team you can create many teams of this type and add members with roles of those teams.

The initial generation of the project, generate a default type of team. It is the type "Site".
You can start the application and go in Site menu to understand the usage.

In the following code sample replace [YourTeamType] by the name of your type type.

## Back

### Add the team type

Add the TeamType :
- In Crosscutting.Common\Enum\TeamTypeId.cs 
  - add in enum TeamTypeId: the new teamType and increment the Id value.
  ```csharp
    /// <summary>
    /// Value for site.
    /// </summary>
    [YourTeamType] = [IdTeamType],
  ```
  - add in TeamTypeRightPrefix.mapping: the prefix string use for right...
  ```csharp
    { TeamTypeId.[YourTeamType], "[YourTeamType]" },
  ```
- (Optionally) In Crosscutting.Common\Enum\RoleId.cs in enum RoleId
  - add the role that will be use for this type of team (one line per role). ex :
  ```csharp
    [YourRoleName] = [IdRole],
  ```  
- In Infrastructure.Data\ModelBuilders\UserModelBuilder.cs
  - in function CreateTeamTypeModel add your teamType in base:
  ```csharp
    modelBuilder.Entity<TeamType>().HasData(new TeamType { Id = (int)TeamTypeId.[YourTeamType], Name = "[YourTeamType]" });
  ```
  - (Optionally) in function CreateTeamTypeRoleModel add the mapping between the role and your teamType. (one line per role)
  ```csharp
    rt.HasData(new { TeamTypesId = (int)TeamTypeId.[YourTeamType], RolesId = (int)RoleId.[YourRoleName] });
  ```

- In Application\User\AuthAppService.cs
  - (Optionally) add computed role
  ```csharp
    if (currentTeam.TeamTypeId == (int)TeamTypeId.[YourRoleName])
    {
        allRoles.Add(Constants.Role.[YourRoleName]Member);
    }
  ```
- In AuthController > function Login() > variable loginParam
  - add following line adapt roleMode and inHeader
  ```csharp
    new TeamConfigDto { TeamTypeId = (int)TeamTypeId.[YourTeamType], RoleMode = RoleMode.AllRoles, InHeader = true },
  ```

### Add the team CRUD

Duplicate the files of Site elements and replace Site by the name of your team.
You have: 
- Infrastructure.Data\ModelBuilders\SiteModelBuilder.cs
- Domain\SiteModule\ ...
- Domain.Dto\Site\ ...
- Application\Site\ ...
- Presentation.Api\Controllers\Site\SitesController.cs

And similar to [CRUD_Back](../20-CRUD/10-CreateACRUD.md) the basic right just be added in
- CrossCutting.Common\Right.cs
- Presentation.Api\bianetconfig.json
  
For injection similar to [CRUD_Back](../20-CRUD/10-CreateACRUD.md) update:
- Crosscutting.Ioc\IocContainer.cs:
    => Into the “ConfigureApplicationContainer” function add a Transient on the service.

In addition, to finish update the database.

## Front
### Add the team type
- In Angular\src\app\shared\constants.ts
  - In TeamTypeId add the team type id (similar to back)
  ```ts
    [YourTeamType] = [IdTeamType],
  ```
  - In TeamTypeRightPrefix dictionary add the mapping with prefix (similar to back) 
  ```ts
    {key: TeamTypeId.[YourTeamType], value: "[YourTeamType]"},
  ```
- In Angular\src\environments\all-environments.ts
  - add the following line and adapt roleMode and inHeader similarly to loginParam in back
  ```ts
    { teamTypeId: TeamTypeId.[YourTeamType], roleMode: RoleMode.AllRoles, inHeader: true },
  ```


### Add the team CRUD
The procedure is similar to the [CRUD_Front](../20-CRUD/20-CreateACRUD.md) but you will use the zip **aircraft-maintenance-companies.zip** instead of **feature-planes.zip**

### Filter Sub teams in header
In case of a team type child of team type you have to filer the children teams by their parent.
Modify the LoginOnTeamsAsync(LoginParamDto loginParam) function in AuthAppService.cs.
Example for a team type "MaintenanceTeam" child of a team type "AircraftMaintenanceCompany"
```csharp
    AdditionalInfoDto additionalInfo = null;
    if (loginParam.AdditionalInfos)
    {
        // TO REMOVE additionalInfo = new AdditionalInfoDto { UserInfo = userInfo, UserProfile = userProfile, Teams = allTeams.ToList() };

        // BEGIN CUSTOMIZATION
        CurrentTeamDto currentAircraftMaintenanceCompany = userData.CurrentTeams?.FirstOrDefault(ct => ct.TeamTypeId == (int)TeamTypeId.AircraftMaintenanceCompany);
        additionalInfo = new AdditionalInfoDto
        {
            UserInfo = userInfo, UserProfile = userProfile,
            Teams = allTeams.Where(t => t.TeamTypeId != (int)TeamTypeId.MaintenanceTeam || t.ParentTeamId == currentAircraftMaintenanceCompany?.TeamId).ToList(),
        };

        // END CUSTOMIZATION
    }
```