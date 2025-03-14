---
title: Troubleshooting V4.0.2
---
# Troubleshooting on the known issues in the Framework V4.0.2

## Issues to correct manually:

### DTO + CRUD generation : 
If you generate a DTO and after a CRUD on the same entity the permission Option disappear from

### Connector
If you generate an application without Front feature you should add this variable in AuthAppService
```csharp
/// <summary>
/// The ldap repository service.
/// </summary>
private readonly ILdapRepositoryHelper ldapRepositoryHelper;
```

## Issues in V4.0.0 corrected in V4.0.2 :
* Fix on List and Item service when form model doesn't extend view model
* Fix design button notifications
* Import/Export - fix Duplicate Id
* Double scroll on Hangfire board when small screen
* Fix BiaAuthorizationPolicyProvider
* Bad translation in team advanced filter
* Lost row focus when leaving multiselect in calcmode
* Scrolling issue on the configuration menu in the sidebar
* Height calculation problem in horizontal mode on small screens
* Create CleanTask hangfire
* Read Only Mode in BIA Docs incorrect + Example in BIADemo
* The BACK_TO_BACK AUTH force GetUserRolesAsync every time
* The LoginAndTeam is called twice at each startup



    
