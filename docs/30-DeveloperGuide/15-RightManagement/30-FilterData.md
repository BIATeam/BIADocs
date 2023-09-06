---
layout: default
title: Filter data
parent: Right management
grand_parent: Developer guide
nav_order: 30
---

# Filter data
This file explains how to filter data by the team.

## Data model
Check that the data model is compliant with the recomandation in :
 [Develop application](../../20-WorkWithBIA/20-DevelopApplication/DevelopTheApplication.md)

## Filter in service
If the data model is correct for every item table you have an link on an unique team.

For all service that inharit of **FilteredServiceBase** (or **CrudAppServiceBase** ...) you can implement a security filter in the service constructor.
Filter can be apply at different level : All, Read, Update, Delete
- If **Delete** filter is not defined the Delete filter use the **Update** filter
- If **Update** filter is not defined the Update filter use the **Read** filter
- If **Read** filter is not defined the Update filter use the **All** filter
- If **All** filter is not defined there is no restriction.

All actions that get data (GetAllAsync, GetCsvAsync, GetRangeAsync ...) use the Read filter by default (it can be change in the parameter **accessMode**)
All actions that update data (UpdateAsync ...) use the Update filter by default (it can be change in the parameter **accessMode**)
All actions that delete data (RemoveAsync ...) use the Delete filter by default (it can be change in the parameter **accessMode**)

### Implement a filter on current team
General usage for a service of a **item table**:
The current team (selected in upper right combo) is accessible with userData.GetCurrentTeamId.
You can write the filter with an linq syntaxt that compare the team of the item with the current Site (p => p.SiteId in following example) 
```csharp
    public PlaneAppService(ITGenericRepository<Plane, int> repository, IPrincipal principal)
        : base(repository)
    {
        var userData = (principal as BIAClaimsPrincipal).GetUserData<UserDataDto>();
        this.currentSiteId = userData != null ? userData.GetCurrentTeamId((int)TeamTypeId.Site) : 0;
        this.filtersContext.Add(AccessMode.Read, new DirectSpecification<Plane>(p => p.SiteId == this.currentSiteId));
    }
```

### Implement a filter read on role on lock update on current team
General usage for a service of a **team table**:
The user with AccesAll right can see every team (it is for the administrators)
The users can see the teams where there are member.
The update is lock on current team, with the additionnal security of right in controller it ensure that only authorised user can perform modification.

```csharp
    public AircraftMaintenanceCompanyAppService(ITGenericRepository<AircraftMaintenanceCompany, int> repository, IPrincipal principal)
        : base(repository)
    {
        var userData = (principal as BIAClaimsPrincipal).GetUserData<UserDataDto>();
        var currentAircraftMaintenanceCompanyId = userData != null ? userData.GetCurrentTeamId((int)TeamTypeId.AircraftMaintenanceCompany) : 0;

        IEnumerable<string> currentUserPermissions = (principal as BIAClaimsPrincipal).GetUserPermissions();
        bool accessAll = currentUserPermissions?.Any(x => x == Rights.Teams.AccessAll) == true;
        int userId = (principal as BIAClaimsPrincipal).GetUserId();

        // You can see evrey team if your are member
        // For AircraftMaintenanceCompany we add
        //          - right for privilate acces (AccessAll) = Admin
        this.FiltersContext.Add(
            AccessMode.Read,
            new DirectSpecification<AircraftMaintenanceCompany>(p => accessAll || p.Members.Any(m => m.UserId == userId)));

        // In teams the right in jwt depends on current teams. So you should ensure that you are working on current team.
        this.FiltersContext.Add(
            AccessMode.Update,
            new DirectSpecification<AircraftMaintenanceCompany>(p => p.Id == currentAircraftMaintenanceCompanyId));
    }
```


### Implement a filter read on role on lock update on current team and parent team
General usage for a service of a **team table** that is child of an other **team table**:
The user with AccesAll right can see every teams children of the current parent team.
The users can see the teams children of the current parent team where there are member .
The update is lock on current team, with the additionnal security of right in controller it ensure that only authorised user can perform modification.
```csharp
        /// <summary>
        /// Initializes a new instance of the <see cref="MaintenanceTeamAppService"/> class.
        /// </summary>
        /// <param name="repository">The repository.</param>
        /// <param name="principal">The claims principal.</param>
        public MaintenanceTeamAppService(ITGenericRepository<MaintenanceTeam, int> repository, IPrincipal principal)
            : base(repository)
        {
            var userData = (principal as BIAClaimsPrincipal).GetUserData<UserDataDto>();
            this.currentAircraftMaintenanceCompanyId = userData != null ? userData.GetCurrentTeamId((int)TeamTypeId.AircraftMaintenanceCompany) : 0;
            var currentMaintenanceTeamyId = userData != null ? userData.GetCurrentTeamId((int)TeamTypeId.MaintenanceTeam) : 0;

            IEnumerable<string> currentUserPermissions = (principal as BIAClaimsPrincipal).GetUserPermissions();
            bool accessAll = currentUserPermissions?.Any(x => x == Rights.MaintenanceTeams.ListViewAll) == true;
            int userId = (principal as BIAClaimsPrincipal).GetUserId();

            // You can see every team if your are member
            // For MaintenanceTeam we add
            //          - filter on current AircraftMaintenanceCompany to see only MaintenanceTeam of the current AircraftMaintenanceCompany
            //          - right for privilate acces (ListViewAll) = Admin and Supervisor of the Parent team (AircraftMaintenanceCompany)
            //          - right for member of the current AircraftMaintenanceCompany
            this.FiltersContext.Add(
                AccessMode.Read,
                new DirectSpecification<MaintenanceTeam>(p => p.AircraftMaintenanceCompanyId == this.currentAircraftMaintenanceCompanyId && (accessAll || p.Members.Any(m => m.UserId == userId || p.AircraftMaintenanceCompany.Members.Any(m => m.UserId == userId)))));

            // In teams the right in jwt depends on current teams. So you should ensure that you are working on current team.
            this.FiltersContext.Add(
                AccessMode.Update,
                new DirectSpecification<MaintenanceTeam>(p => p.Id == currentMaintenanceTeamyId));
        }
```

### Implement a filter for parameter table
General usage for a service of a **parameter table**
Data are filter on a buisnes rule.
```csharp
    /// <summary>
    /// Initializes a new instance of the <see cref="UserAppService" /> class.
    /// </summary>
    /// <param name="repository">The repository.</param>
    /// <param name="userSynchronizeDomainService">The user synchronize domain service.</param>
    /// <param name="configuration">The configuration of the BiaNet section.</param>
    /// <param name="userDirectoryHelper">The user directory helper.</param>
    /// <param name="logger">The logger.</param>
    /// <param name="userContext">The user context.</param>
    /// <param name="identityProviderRepository">The identity provider repository.</param>
    /// <param name="userIdentityKeyDomainService">The user Identity Key Domain Service.</param>
    public UserAppService(
        ITGenericRepository<User, int> repository)
        : base(repository)
    {
        this.FiltersContext.Add(AccessMode.Read, new DirectSpecification<User>(u => u.IsActive));
    }
```

### Do not implement a filter for technical table
General usage for a service of a **technical table**
There isn't controller that access to the service, only internal job.
So it is not necessary to filter the data.