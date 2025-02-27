---
sidebar_position: 1
---

# Initialize Keycloak

This file explains how to initialize Keycloak for use with a BIA application.

We will take the connection with an LDAP as an example.

## Realm
Never modify the **Master** realm.

Create a new **Realm**, for example **BIA-Realm**

 ## Service Account

You must create a user in Keycloak which will be used to query the list of users in your realm.

In your realm, go to the **User** tab and create a user. Once created, create a non-temporary password.

Go to the **Role Mapping** tab and click on **Assign Role**

Select **Filter by clients** and select the following roles:

- **realm-management** query-users
- **realm-management** view-users

If you want to keep eMail, first name and last name as mandatory field for all user, complete them with dummy data for this user.
Else you can disable the mandatory on this fields : see chapter in this page "Simplify Authentication flow" > "Remove “Update Account Information” form after first login"


If you use the sample configuration file (bianetconfig.Example_Development.json) :
- This user should be parameter in your vault with the key BIA:KeycloakSearchUserAccount 
- Or in the environment variables : KC_SA_USERNAME and KC_SA_PASSWORD (it need to comment the line "VaultCredentialsKey": "BIA:KeycloakSearchUserAccount",)

## Client
Create a new client, for example, biaapp and fill **Root URL** and **Admin URL** with the root of your applications' URLs (example: https://myapp-int.mydomain/ or for development: http://localhost:4200/)
 ![createClient1](../../Images/Keycloak/createClient1.png)
 ![createClient2](../../Images/Keycloak/createClient2.png)
 ![createClient3](../../Images/Keycloak/createClient3.png)

## Client Scopes
Go to the tab **Client scopes** and click on the link **biaapp-dedicated** contained in the table with the description: **Dedicated scope and mappers for this client**

 ![dedicated-mappers](../../Images/Keycloak/dedicated-mappers.jpg)

 If they are missing, add them:
* User Property :
  Important Token Clain name should be : 
   ```
   http://schemas\.xmlsoap\.org/ws/2005/05/identity/claims/name
   ```
  ![dedicated-mappers-userName](../../Images/Keycloak/dedicated-mappers-userName.jpg)

* Audience
  ![dedicated-mappers-audience](../../Images/Keycloak/dedicated-mappers-audience.jpg)

* Group Membership (for an ldap authentication)
  ![dedicated-mappers-groups](../../Images/Keycloak/dedicated-mappers-groups.jpg)


## User federation (for an ldap authentication)
Create a new **User federation**, configure it, example:

![LDAP-Connection-authentication-settings](../../Images/Keycloak/LDAP-Connection-authentication-settings.jpg)

![LDAP-searching-updating](../../Images/Keycloak/LDAP-searching-updating.jpg)

And check that everything is ok with the buttons **Test connection** and **Test authentication**

![check-ldap-success](../../Images/Keycloak/check-ldap-success.jpg)

Among the fields requested in the **User** table in database, look at what the **User federation** contains. If any are missing, create the corresponding mappers.

![user-federation-mapper](../../Images/Keycloak/user-federation-mapper.jpg)

configure groupldap as follows:

**LDAP Filter**: (&(objectCategory=CN=Group,CN=Schema,CN=Configuration,DC=your,DC=ad)(|(cn=GROUP_AD_PREFIX_TO_FILTER_*)(cn=GROUP_AD_TO_FILTER)))

![user-federation-mapper-groupldap](../../Images/Keycloak/user-federation-mapper-groupldap.jpg)


At the top right, select from the list, **Sync all users**

![sync-all-user](../../Images/Keycloak/sync-all-user.jpg)

# Simplify Authentication flow

## Remove “Update Account Information” form after first login
To remove “Update Account Information” form after first login
 ![update account information](../../Images/Keycloak/UpdateAccountInformation.png)

In Keycloak interface > menu "Realm settings" > tab "User profile" > edit the 3 field (email, firstName, lastName)
and switch Required field to off. 

 ![email setting](../../Images/Keycloak/emailSettings.JPG)



## Remove the step "Review Profile"
To remove the step that propose to review the profile when account already exist
 ![step Review Profile](../../Images/Keycloak/ReviewProfile.jpg)

In Keycloak interface > menu "Authentication" > tab "Flow" > click on "first broker login"

<<<<<<< HEAD
=======
# Simplify Authentication flow

## Remove “Update Account Information” form after first login
To remove “Update Account Information” form after first login
 ![update account information](../../Images/Keycloak/UpdateAccountInformation.png)

In Keycloak interface > menu "Realm settings" > tab "User profile" > edit the 3 field (email, firstName, lastName)
and switch Required field to off. 

 ![email setting](../../Images/Keycloak/emailSettings.JPG)


<<<<<<< HEAD
=======
# Simplify Authentication flow

## Remove “Update Account Information” form after first login
To remove “Update Account Information” form after first login
 ![update account information](../../Images/Keycloak/UpdateAccountInformation.png)

In Keycloak interface > menu "Realm settings" > tab "User profile" > edit the 3 field (email, firstName, lastName)
and switch Required field to off. 

 ![email setting](../../Images/Keycloak/emailSettings.JPG)


>>>>>>> 654da63ffb2d1509efeaa04521212f4aef9c92d5

## Remove the step "Review Profile"
To remove the step that propose to review the profile when account already exist
 ![step Review Profile](../../Images/Keycloak/ReviewProfile.jpg)

In Keycloak interface > menu "Authentication" > tab "Flow" > click on "first broker login"

<<<<<<< HEAD
>>>>>>> 654da63ffb2d1509efeaa04521212f4aef9c92d5
=======
>>>>>>> 654da63ffb2d1509efeaa04521212f4aef9c92d5
Change the requirement of "Confirm link existing account" to "Disabled"
 ![authentication flow](../../Images/Keycloak/AuthFlow.jpg)