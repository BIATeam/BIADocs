---
sidebar_position: 1
---

# User management
This file explains how users are manage in the BIA framework.

## User Screen
In the User screen you can manage user:
- Add users from a Ldap or an identity provider (keycloack)
- Remove users
- Modify the role assignement at root level

## Authentication
Authentication is parametrized in the bianetconfig files (depending of the environment) in section Authentication
It can be based on Ldap or keycloack

For Ldap you have to specify the dommain to use.
If a specific user is use to consult the ldap, the user and password should be store in windows vault.
You should specify if those domain contains group and or user.
In name you should specify the short name of the domaine (ie the word you use before the \ in login sequence)
```json
"Authentication": {
  "LdapDomains": [
    {
      "Name": "DOMAIN_BIA_1",
      "LdapName": "the-user-domain1-name.bia",
      "ContainsGroup": true,
      "ContainsUser": true
    },
    {
      "Name": "DOMAIN_BIA_2",
      "LdapName": "the-user-domain3-name.bia",
      "CredentialKeyInWindowsVault": "BIA:LDAP://the-user-domain3-name.bia",
      "ContainsGroup": true,
      "ContainsUser": true
    },
    {
      "Name": "DOMAIN_BIA_SRV",
      "LdapName": "the-server-domain-name.bia",
      "CredentialKeyInWindowsVault": "BIA://LDAP:the-server-domain-name.bia",
      "ContainsGroup": true,
      "ContainsUser": false
    }
  ]
}
```

For keycloak consult the specific page [Keycloak](./50-Keycloak.md)

## Authorization
Authorization is based on roles.
The roles of an users are calculated when the user login and store in the jwt token.
Main roles comes from ownership to AD Groups, keycloak Groups and be in the table user.
  The role "User" give the authorization to access to the application.
  The role "Admin" give the authorization to access to the application and some important function to configure the application at startup.
Fine roles are directly set to the user in the application.

Roles is parametrized in the bianetconfig files (depending of the environment) in section Roles
### Fake

If the role is defined as 'Fake', the role specified in the label is assigned. (generally use during development)

```json
{
  "Label": "User",
  "Type": "Fake"
}
```

### UserInDB

If the role is defined as 'UserInDB', and the user both exists in the database and is active, then the role specified in the label is assigned.

```json
{
  "Label": "User",
  "Type": "UserInDB"
}
```

### ClaimsToRole

This type is used when a user's claims are employed to determine the user's role. Claims are pieces of information about the user that are embedded in the authentication token and are typically used for authorization purposes. If the role requires a claim and that particular claim is included in the user's claims, then the role specified in the label is assigned.

```json
{
  "Label": "Admin",
  "Type": "ClaimsToRole",
  "RequireClaim": {
    "Type": "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
    "AllowedValues": [ "S-1-5-21-3284204050-131030045-9876543211-853112" ]
  }
}
```

In this example:

- `RequireClaim` is an object that specifies what claim needs to be present in the user's authentication token for this role to be assigned. In this instance:

   - `"Type": "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid"`: Specifies the type of claim we're looking for in the user's authentication token.
   
   - `"AllowedValues": [ "S-1-5-21-3284204050-131030045-9876543211-853112" ]`: The array represents the acceptable values for the claim. If the user's claim value matches "S-1-5-21-3284204050-131030045-9876543211-853112", the user will be assigned the 'Admin' role.


### Ldap

This role type is related to authentication via an LDAP directory. If the role is defined as 'Ldap' and if the user's Security Identifier (SID) is in the specified LDAP groups, then the role label is returned.

```json
  "Roles": [
    {
      "Label": "User",
      "Type": "Ldap",
      "LdapGroups": [
        {
          "AddUsersOfDomains": [ "DOMAIN_BIA_1", "DOMAIN_BIA_2" ],
          "RecursiveGroupsOfDomains": [ "DOMAIN_BIA_1", "DOMAIN_BIA_2" ],
          "LdapName": "DOMAIN_BIA_1\\PREFIX-APP_BIADemo_INT_User",
          "Domain": "DOMAIN_BIA_1"
        }
      ]
    },
    {
      "Label": "Admin",
      "Type": "Ldap",
      "LdapGroups": [
        {
          "RecursiveGroupsOfDomains": [ "DOMAIN_BIA_1", "DOMAIN_BIA_2" ],
          "LdapName": "DOMAIN_BIA_1\\PREFIX-APP_BIADemo_INT_Admin",
          "Domain": "DOMAIN_BIA_1"
        }
      ]
    }
  ]
```

## Users synchronization with LDAP
On the user screen there is a button that synchronize the user properties with Ldap (there is a cache of 1800 minute, settings LdapCacheUserDuration in bianetconfig.json).
A worker task synchronize them after cleaning the cache.

If the roles use AD groups the member of the groups are synchronize with the button and the Worker task (there is a cache of 200 minutes settings LdapCacheGroupDuration in bianetconfig.json)
The group cache is clear by the Worker Task or when a user is added or deleted in the application.

The action to add or delete a user force the synchronization.