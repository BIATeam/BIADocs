---
sidebar_position: 1
---

# Initialize Keycloak

This file explains how to initialize Keycloak for use with a BIA application.

We will take the connection with an LDAP as an example.

## Realm
Never modify the **Master** realm.

Create a new **Realm**, for example **BIA-Realm**

## User federation
Create a new **User federation**, configure it, example:

![LDAP-Connection-authentication-settings](../../Images/Keycloak/LDAP-Connection-authentication-settings.jpg)

![LDAP-searching-updating](../../Images/Keycloak/LDAP-searching-updating.jpg)

And check that everything is ok with the buttons **Test connection** and **Test authentication**

![check-ldap-success](../../Images/Keycloak/check-ldap-success.jpg)

Among the fields requested in the **User** table in database, look at what the **User federation** contains. If any are missing, create the corresponding mappers.

![user-federation-mapper](../../Images/Keycloak/user-federation-mapper.jpg)

configure groupldap as follows:

**LDAP Filter**: (&(objectCategory=CN=Group,CN=Schema,CN=Configuration,DC=one,DC=ad)(|(cn=GP_S007_Digital_Perm_ServiceApi_*)(cn=GP_S007_Digital_Role_App_Admin)))

![user-federation-mapper-groupldap](../../Images/Keycloak/user-federation-mapper-groupldap.jpg)


At the top right, select from the list, **Sync all users**

![sync-all-user](../../Images/Keycloak/sync-all-user.jpg)

## Client
Create a new client, for example, biaapp and fill **Root URL** and **Admin URL** with the root of your applications' URLs (example: https://myapp-int.mydomain/)

Go to the tab **Client scopes** and click on the link **biaapp-dedicated** contained in the table with the description: **Dedicated scope and mappers for this client**

 ![dedicated-mappers](../../Images/Keycloak/dedicated-mappers.jpg)

 If they are missing, add them:

 ![dedicated-mappers-userName](../../Images/Keycloak/dedicated-mappers-userName.jpg)

 ![dedicated-mappers-groups](../../Images/Keycloak/dedicated-mappers-groups.jpg)

 ![dedicated-mappers-audience](../../Images/Keycloak/dedicated-mappers-audience.jpg)

 ## Service Account

You must create a user in Keycloak which will be used to query the list of users in your realm.

In your realm, go to the **User** tab and create a user. Once created, create a non-temporary password.

Go to the **Role Mapping** tab and click on **Assign Role**

Select **Filter by clients** and select the following roles:

- **realm-management** query-users
- **realm-management** view-users
