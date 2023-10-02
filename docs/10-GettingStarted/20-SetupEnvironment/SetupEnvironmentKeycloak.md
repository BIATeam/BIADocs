---
layout: default
title: Setup Keycloak
parent: Setup environment
grand_parent: Getting Started
nav_order: 6
---

# Initialize Keycloak

This file explains how to initialize Keycloak for use with a BIA application.

We will take the connection with an LDAP as an example.

## Realm
Never modify the **Master** realm.

Create a new **Realm**, for example **BIA-Realm**

## User federation
Create a new **User federation**, configure it and check that everything is ok with the buttons **Test connection** and **Test authentication**

![check-ldap-success](/docs//Images//Keycloak/check-ldap-success.jpg)

Among the fields requested in the **User** table in database, look at what the **User federation** contains. If any are missing, create the corresponding mappers.

![user-federation-mapper](/docs//Images//Keycloak/user-federation-mapper.jpg)

At the top right, select from the list, **Sync all users**

![user-federation-mapper](/docs//Images//Keycloak/sync-all-user.jpg)

## Client
Create a new client, for example, biaapp and fill **Root URL** and **Admin URL** with the root of your applications' URLs (example: https://myapp-int.mydomain/)

Go to the tab **Client scopes** and click on the link **biaapp-dedicated** contained in the table with the description: **Dedicated scope and mappers for this client**

 ![dedicated-mappers](/docs//Images//Keycloak/dedicated-mappers.jpg)

 If they are missing, add them:

 ![dedicated-mappers-userName](/docs//Images//Keycloak/dedicated-mappers-userName.jpg)

 ![dedicated-mappers-lastName](/docs//Images//Keycloak/dedicated-mappers-lastName.jpg)

 ![dedicated-mappers-emailName](/docs//Images//Keycloak/dedicated-mappers-email.jpg)

 ![dedicated-mappers-countryName](/docs//Images//Keycloak/dedicated-mappers-country.jpg)

 ![dedicated-mappers-firstName](/docs//Images//Keycloak/dedicated-mappers-firstName.jpg)

 ![dedicated-mappers-distinguishedName](/docs//Images//Keycloak/dedicated-mappers-distinguishedName.jpg)

 ![dedicated-mappers-client-roles](/docs//Images//Keycloak/dedicated-mappers-client-roles.jpg)

 ![dedicated-mappers-realm-roles](/docs//Images//Keycloak/dedicated-mappers-realm-roles.jpg)

 ### Role client
 In the chapter above, we explain how to add the client and realm roles.
 
 In the **Realm Roles** menu, you can create roles. same thing in the **Client** tab for your client.
 
 Once the roles have been created, go to **Users** tab, select a user and assign the roles.
 
## Service Account

You must create a user in Keycloak which will be used to query the list of users in your realm.

In your realm, go to the **User** tab and create a user. Once created, create a non-temporary password.

Go to the **Role Mapping** tab and click on **Assign Role**

Select **Filter by clients** and select the following roles:

- **realm-management** query-users
- **realm-management** view-users

