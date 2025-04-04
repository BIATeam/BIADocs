---
sidebar_position: 1
---

# ChangeLog 
## V3.9.0 (2024-07-09)
* Mapper are injectable, and can be customize with injectable parameters (userId, permission...)
* Right on team are review to be more flexible with children teams.
### Angular
* CRUD:
  * Multi sort (can sort by several column with ctrl key)
  * Site members : display and sort by last name (and not first name).
  * Add filters : not end with / not start with / empty date / not empty date.
  * Filter header adapted to all type
  * Possibility to export/import at csv format for massif add, update or delete.
  * Fix position of a column.
* CRUD + forms : Additional parameter on field
  * isVisible: possibility to hide a field.
  * isOnlyInitializable: field can be change at creation but not at update.
  * isOnlyUpdatable: field can be change at update but not at creation.
  * displayFormat: BiaFieldNumberFormat > manage the display format for decimal and currency field.
* Added error log in all controller actions.
* Translation of roles in headers
* Fix time display + 2 after edit
* Fix notification does not go to read
* Fix pb shared view team setting by default
* Fix right management for team child of team.
* Improve lint.
* Fix pb scroll navigation if number of lines displayed important.
* Fix field disabled, the value disappears from the edit inline list.
* Fix When you activate the Angular service worker and deactivate it => weird behavior.
* Expand combo list of columns.
* Name extracted .csv file contains the view name.
* Fix Excel like uncorrelate canEdit/canAdd
* Fix bug dropdown excel like
* Fix error selected elements BiaTable.
* Fix If 2 identical view s, impossible to select the 2nd.
* Fix Searching for "column display" combobox doesn't work.
* Fix combobox color problem "SelectRole".
* Replace deprecated function in front.

### DotNet
* .Net 8
* Access unauthorize render a 403 error (no more 500)
* Use a list of WebApp to wake up to not have to comment code when back or front only or 2 front.
* Clean distributed cache at deploy db.
* Replace Bulk insert by a mode (only compatible SQLserver)
* Bulk Update and Delete are deprecated => should use .Net 8 native method.
* Improve GetAllElementsAndCountAsync with ReadOnly

  
## V3.8.0 (2023-10-31)
* More compliant with IISExpress and use port 32128
* Possibility to be without database for WebApi used as Connector:
  * Remove User info in Token light.
  * Button token light added swagger to be able to test.
  * Disable distributed cache is possible.
  * BIADistributedCache switch to BIALocalCache if distributed cache is disable
  
### Angular
* Angular 16.
* Remove flex-layout.
* Add badge on filter when there is a filter on a column.
* Add custom validators.
* Translate of the role in User list, fix when language change.
* Remove icon in list title if not sorted
* Possibility to set an icon instead of the title in CRUD list.

### DotNet
* UserManager is optional, specific mapping Role to permission can be manage by environment. 
* Keycloak authentication review.
* Add Draw io model.
* Add TOptionDto for non int id.
* Separate setting between IIS and IISExpress.
* Add direct navigation in junction (for new crud only).
* Add NLog rule for EntityFrameworkCore.
* Add the permission Background_Task_Admin for Admin.
* Remove unencrypted token.
* Swagger GetAll works without change parameters
* Display error message when deployDB crash at deployment.
* Get AD Group form authentication claims (faster and no cache needed).
* Stop deployment if error during deployDB
* Timeout for deployDb is configurable
* Fix sync user crash when login not in AD
* Fix stop service and App pool at deployment.

## V3.7.5.1 (Patch - 2023-09-19)
### DotNet
* Add NLog rule for EntityFrameworkCore.

## V3.7.5 (Patch - 2023-09-14)
* More compliant with IISExpress

### DotNet
* Correct bug on non active user when UserInDB not use, that create huge log and consume lot of CPU.
* Correct daily synchronization in UserInDB mode.

## V3.7.4.1 (Patch - 2023-07-12)
### DotNet
* BIA.Net.Core.Infrastructure.Service: Correct a bug with user group synchronization.

## V3.7.4 (Patch - 2023-06-16)
### DotNet
* Add the Mode LdapWithSidHistory.
* Faster management of ForeignSecurityIdentity.
* Add Filter on ldapDomain to search faster users.

## V3.7.3 (Patch - 2023-05-12)
### DotNet
* Check identity on Login only
* User In DB
* Separate role UserManager from Admin

## V3.7.2 (2022-12-05)
### Angular
* Correct update roles on existing member.

## V3.7.1 (2022-10-03)
* Header filter can now take complex criteria (date before, after, contains, begins... and, or).
* Teams: Remove TeamId Parameter
* Teams: Template style for member
### Angular
* Advanced filter more robust
* Standardize Sites, Users and Members CRUD
* Team new format  (for new creation only)
* Fix Date Format

## V3.7.0 (2022-09-14)
* ```npm start``` is now for IIS Express (use ```npm run start4iis``` to launch the angular for IIS)
* Add KeyCloak compatibility
* Correct Matomo tracking (bug introduce in V3.6.0)
### DotNet
* .Net6.0
* Add Linux Container compatibility
* The worker service run in a service (no more in a web application)
* WebApiRepository.PostAsync parameter for body doesn't expect a json string anymore but the object or list of objects. Stringification is handled by the PostAsync method.
  >```WebApiRepository.PostAsync<T, U>(string url, U body, bool useBearerToken = false, bool isFormUrlEncoded = false)```
### Angular
* Angular 13, PrimeNg 13, PrimeIcon V5
* Keep state of the BiaTable View when live and come back to a screen (only when view is activated)
* Possibility to sort the column.
* Extract based on the sort and selection of the column.
* The table header controller component design changes. the view and show lists are now positioned on the left. The list scrollbar is higher.
* Lighter application (remove unused dependencies)
* Solve bug in CRUD index when deselect all.
* Possibility to switch modes of CRUD (view, calc, offline, popup)

## V3.6.5.1 (Patch - 2023-09-19)
### DotNet
* Add NLog rule for EntityFrameworkCore.

## V3.6.5 (Patch - 2023-09-14)
* More compliant with IISExpress
### DotNet
* Correct bug on non active user when UserInDB not use, that create huge log and consume lot of CPU.
* Correct daily synchronization in UserInDB mode.

  
## V3.6.4.1 (Patch - 2023-07-12)
### DotNet
* BIA.Net.Core.Infrastructure.Service: Correct a bug with user group synchronization.
  
## V3.6.4 (Patch - 2023-06-15)
### DotNet
* Add the Mode LdapWithSidHistory.
* Faster management of ForeignSecurityIdentity.
* Add Filter on ldapDomain to search faster users.

## V3.6.3 (Patch - 2023-05-12)
### DotNet
* Check identity on Login only
* User In DB
* Separate role UserManager from Admin

## V3.6.2 (2022-06-17)
### DotNet
* Correct right for admin at start uo (add permission for role Admin: User_Options, Roles_Option, "Notification_List_Access", "Notification_Delete", "Notification_Read" + Get the current Teams when Admin)
* Correct deployment (BiaNetConfig.json bad formated)
* Correct the Bulk Update and Delete when pool user not db_owner of the dataBase
### Front
* Offline bug : Endpoint missing in post, multiple call to back, token that does not refresh, add an observable triggered at the end of the syncho.

## V3.6.1 (2022-05-06)
* Change the format of the NotificationTeamDto
### DotNet
* Correct bug in inheritance of CrudAppServiceListAndItemBase
### Angular
* Notification edition work for notified teams
* Refresh notification when read
* Refresh star when select default site/role

## V3.6.0 (2022-05-02)
* DB Event Auditing
* Rights and views by teams
* Offline mode
* Cross or team notifications
* Adding users from AD for Site_Admin
* Hangfire authentication JWT
### DotNet
* Read only context is usable with the repository
* Bulk insert, update and delete is usable with the repository (without license)
* WebApi connector (abstract class)
* Helper impersonation
### Angular
* New organistion for bia domain and bia repository, placed in separate folder

## V3.5.5.1 (Patch - 2023-09-19)
### DotNet
* Add NLog rule for EntityFrameworkCore.

## V3.5.5 (Patch - 2023-09-18)
* More compliant with IISExpress
### DotNet
* Correct bug on non active user when UserInDB not use, that create huge log and consume lot of CPU.
* Correct daily synchrnonisation in UserInDB mode.

## V3.5.4.1 (Patch - 2023-07-12)
### DotNet
* BIA.Net.Core.Infrastructure.Service: Correct a bug with user group synchronization.
  
## V3.5.4 (Patch - 2023-06-14)
### DotNet
* Add the Mode LdapWithSidHistory.
* Faster management of ForeignSecurityIdentity.
* Add Filter on ldapDomain to search faster users.

## V3.5.3 (Patch - 2023-05-12)
### DotNet
* Check identity on Login only
* User In DB
* Separate role UserManager from Admin

## V3.5.1 (2022-02-08)
* Possibility to inject ExternalJS in front depending on back environement. 
### DotNet
* Solve bug in order list
### Angular
* Custom Scss include in project
* Correct all roles get signalR notification

## V3.5.0.1 (2022-01-23)
### DotNet
* Solve bug in Test unitary
### Angular
* Breadcrumb disappear at home 
* Correct switch of theme (bug in prod only)
  
## V3.5.0 (2022-01-21)
* Manage Time only with or without second
### DotNet
* Manage Id other than int
* Translate in DB (use by role and notification)
* Faster authentication
* Template for CRUD in Doc
### Angular
* Angular 12
* NG lint ok

## V3.4.5.1 (Patch - 2023-09-19)
### DotNet
* Add NLog rule for EntityFrameworkCore.

## V3.4.5 (Patch - 2023-09-18)
* More compliant with IISExpress
### DotNet
* Correct bug on non active user when UserInDB not use, that create huge log and consume lot of CPU.
* Correct daily synchrnonisation in UserInDB mode.
  
## V3.4.4.1 (Patch - 2023-07-13)
### DotNet
* BIA.Net.Core.Infrastructure.Service: Correct a bug with user group synchronization.

## V3.4.4 (Patch - 2023-06-13)
### DotNet
* Add the Mode LdapWithSidHistory.
* Faster management of ForeignSecurityIdentity.
* Add Filter on ldapDomain to search faster users.

## V3.4.3 (Patch - 2023-05-12)
### DotNet
* Check identity on Login only
* User In DB
* Separate role UserManager from Admin

## V3.4.2 (2021-10-08)
* notification system (translation of title and description can be temporally done in i18n or not, but it will change in next version)
* The signalR message are now filter by feature and site.
* Authentication send current site and current roles
* Permission table is created
* Roles are translate in i18n files
### DotNet
* The client for hub (SignalR) in now a domain service

## V3.4.1 (2021-07-16)
* Add general project file (ReadMe + Change Log)
* Remove Doc (now in BIADocs)
### DotNet
* Correct GitIgnore
* The switch to nuget now limit to minor version eg : 3.4.*
* Add launch settings for IIS

## V3.4.0 (2021-07-16)
### DotNet
* .Net5.0
* Bulk function in repository.
* PostgreSQL compatibility.

## V3.3.6.1 (Patch - 2023-09-19)
### DotNet
* Add NLog rule for EntityFrameworkCore.

## V3.3.6 (Patch - 2023-09-15)
* More compliant with IISExpress
### DotNet
* Correct bug on non active user when UserInDB not use, that create huge log and consume lot of CPU.
* Correct daily synchrnonisation in UserInDB mode.
  
## V3.3.5.1 (Patch - 2023-07-13)
### DotNet
* BIA.Net.Core.Infrastructure.Service: Correct a bug with user group synchronization.

## V3.3.5 (Patch - 2023-06-08)
### DotNet
* Add the Mode LdapWithSidHistory.
* Faster management of ForeignSecurityIdentity.
* Add Filter on ldapDomain to search faster users.

## V3.3.4 (Patch - 2023-04-21)
### DotNet
* Check identity on Login only
* User In DB
* Separate role UserManager from Admin

## V3.3.3 (2021-06-25)
### DotNet
* New helper in common to compare string.
### Angular
* Universal Mode for CRUD.
  
## V3.3.2 (2021-05-28)
### Angular
* Possibility for the user to choice his role.
* Click on site open manage member.
* Member is a children of site with related service and breadcrumb.
* Adding the Calc mode for CRUD.
  
## V3.3.1 (2021-03-31)
### DotNet
* DeployDB use native code First mechanism
* Use the new clustered database
* Add the MapperMode flag in FilteredService to not multiplicate mapper when only a part of the field are to update.
* Add the project title on hangfire dashboard.
* Suppress all warning in test and generated code.
  
## V3.3.0 (2021-01-15)
### DotNet
* Add feature management (posibilité to activate and desactivate powerfull feature like swagger, SignalR...)
* Add Unitary Test
* Add feature in Api HubForClients (use SignalR to push messge to all client connected, compatible with multi front) 
* Add feature in Api DelegateJobToWorker (use Hangfire to launch job in the worker) 
* Add feature in worker DatabaseHandler (detect the change in db immediatlty)
* Add feature in worker HubForClients (use the Api feture HubForClients to push message to all web client connected)
* WorkerService is now a web api with the hangfire Dashboard.
### Angular
*  Date bug fix
*  Matomo integration
*  Crud generation support complex name (like plane-type)
*  Add choice of the site for Admin
  
## V3.2.2 (2020-10-16)
### DotNet
* Solve bug with Zodiac user
* Deactivate swagger in no dev environment
* Add color by environment
* Remove the popup when token expire
* Generate a new secret key at deployment
### Angular
*  Color by env.
  
## V3.2.1 (2020-10-16)
### DotNet
* Add the worker service (hangfire)
  
## V3.2.0 (2020-10-16)
### DotNet
* Use of BIA.core nuget package (1 by layer)
* Compatibility with multi ad environment (usage of user sid) => change the database model
### Angular
*  angular 9.1.12

## V3.2.0 (2020-10-16)
### DotNet
* Use of BIA.core nuget package (1 by layer)
* Compatibility with multi ad environment
  
## V3.1.1 (2020-06-26)
### Angular
*  Bug Fix
  
## V3.1.0 (2020-05-04)
* views
  
## V3.0.0 (2020-10-02)
### DotNet
* .NET Core 3.1.1
### Angular
*  angular 8.2.14
