---
layout: default
title: ChangeLog
parent: Migrate an existing project
nav_order: 10
---

# ChangeLog

## V3.7.3 (Patch - 2023-05-12)
### DotNet
* Check identity on Login only
* User In DB
* Separe role UserManager

## V3.7.2 (2022-12-05)
### Angular
* Correct update roles on existing member.

## V3.7.1 (2022-10-03)
* Header filter can now take complex criteria (date before, after, contains, begins... and, or).
### Angular
* Advanced filter more robust
* Standardize Sites, Users and Members CRUD

## V3.7.0 (2022-09-14)
* ```npm start``` is now for IIS Express (use ```npm run start4iis``` to launch the angular for IIS)
* Add KeyCloack compatibility
* Correct Matomo tracking (bug introduce in V3.6.0)
### DotNet
* .Net6.0
* Add Linux Container compatibility
* The worker service run in a service (no more in a web application)
* WebApiRepository.PostAsync parameter for body doesn't expect a json string anymore but the object or list of objects. Stringification is handled by the PostAsync method.
  >WebApiRepository.PostAsync<T, U>(string url, U body, bool useBearerToken = false, bool isFormUrlEncoded = false)
### Angular
* Angular 13, PrimeNg 13, PrimeIcon V5
* Keep state of the BiaTable View when live and come back to a screen (only when view is activated)
* Possibility to sort the column.
* Extract based on the sort and selection of the column.
* The table header controller component design changes. the view and show lists are now positioned on the left. The list scrollbar is higher.
* Lighter application (remove unused dependencies)
* Solve bug in CRUD index when deselect all.
* Possibility to switch modes of CRUD (view, calc, offline, popup)

## V3.6.3 (Patch - 2023-05-12)
### DotNet
* Check identity on Login only
* User In DB
* Separe role UserManager

## V3.6.2 (2022-06-17)
### DotNet
* Correct right for admin at start uo (add permission for role Admin: User_Options, Roles_Option, "Notification_List_Access", "Notification_Delete", "Notification_Read" + Get the current Teams when Admin)
* Correct deployement (BiaNetConfig.json bad formated)
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
* New organistion for bia domain and bia reposotory, placed in separate folder

## V3.5.4 (Patch - 2023-06-14)
### DotNet
* Add the Mode LdapWithSidHistory.
* Faster management of ForeignSecurityIdentity.
* Add Filter on ldapDomain to search faster users.

## V3.5.3 (Patch - 2023-05-12)
### DotNet
* Check identity on Login only
* User In DB
* Separe role UserManager

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

## V3.4.4 (Patch - 2023-06-13)
### DotNet
* Add the Mode LdapWithSidHistory.
* Faster management of ForeignSecurityIdentity.
* Add Filter on ldapDomain to search faster users.

## V3.4.3 (Patch - 2023-05-12)
### DotNet
* Check identity on Login only
* User In DB
* Separe role UserManager

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

## V3.3.5 (Patch - 2023-06-08)
### DotNet
* Add the Mode LdapWithSidHistory.
* Faster management of ForeignSecurityIdentity.
* Add Filter on ldapDomain to search faster users.

## V3.3.4 (Patch - 2023-04-21)
### DotNet
* Check identity on Login only
* User In DB
* Separe role UserManager

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
*  Crud generation support complexe name (like plane-type)
*  Add choice of the site for Admin
  
## V3.2.2 (2020-10-16)
### DotNet
* Solve bug with Zodiac user
* Desactivate swagger in no dev environment
* Add color by environment
* Remove the popup when token expire
* Generate a new secretkey at deployement
### Angular
*  Color by env.
  
## V3.2.1 (2020-10-16)
### DotNet
* Add the worker service (hangfire)
  
## V3.2.0 (2020-10-16)
### DotNet
* Use of BIA.core nugetpackage (1 by layer)
* Compatibility with multi ad environmemt (usage of user sid) => change the database model
### Angular
*  angular 9.1.12

## V3.2.0 (2020-10-16)
### DotNet
* Use of BIA.core nugetpackage (1 by layer)
* Compatibility with multi ad environmemt
  
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
