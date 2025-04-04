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
You can use fixed role for every user (generally use during development):
```json
  "Roles": [
    {
      "Label": "User",
      "Type": "Fake"
    },
    {
      "Label": "Admin",
      "Type": "Fake"
    }
  ]
```

You can use role based on ownership to Ldap groups:
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

Or because user have been add in database:
```json
      {
        "Label": "User",
        "Type": "UserInDB"
      },
```

Or because user is in a Keycloak group:
```json
      {
        "Label": "Admin",
        "Type": "IdP",
        "IdpRoles": [ "BiaAppAdmin" ]
      }
```

## Users synchronization with LDAP
On the user screen there is a button that synchronize the user properties with Ldap (there is a cache of 1800 minute, settings LdapCacheUserDuration in bianetconfig.json).
A worker task synchronize them after cleaning the cache.

If the roles use AD groups the member of the groups are synchronize with the button and the Worker task (there is a cache of 200 minutes settings LdapCacheGroupDuration in bianetconfig.json)
The group cache is clear by the Worker Task or when a user is added or deleted in the application.

The action to add or delete a user force the synchronization.