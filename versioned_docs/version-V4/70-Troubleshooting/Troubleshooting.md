---
title: Troubleshooting V4.0.2
---
# Troubleshooting on the known issues in the Framework V4.

## Issues to correct manually:

## Issues in V4.0.2
### Imports module not working for more than 1 new line : 
If you want to bulk import new rows of data the the import feature, an error appears :
"This Id appears multiple times in the imported file"
To fix that problem, replace in file crud-item-import.service.ts in line 540 (function checkDuplicateIdObjects) :
```ts
    arr.forEach(obj => {
      if (obj.id !== undefined && obj.id !== null) {
        idCount.set(obj.id, (idCount.get(obj.id) || 0) + 1);
      }
    });
```

## Issues in V4.0.2 corrected in V4.0.4 :
### DTO + CRUD generation : 
If you generate a DTO and after a CRUD on the same entity the permission Option disappear from

### Front navigation after CRUD generation (BIAToolKit V1.8.0.0)
If the link generated in the menu redirect you to the root pages it is probably because the path in navigation is in camelCase but it should be in kebab-case. Example:
```json
path: ['/db-engine-types'],
```

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



    
