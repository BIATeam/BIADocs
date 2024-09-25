---
sidebar_position: 1
---

# Explanation of RoleType

This document details the different role types managed by RoleType.

## RoleType.Fake

If the role is defined as 'Fake', the role specified in the label is assigned.

```json
{
  "Label": "User",
  "Type": "Fake"
}
```

## RoleType.UserInDB

If the role is defined as 'UserInDB', and the user both exists in the database and is active, then the role specified in the label is assigned.

```json
{
  "Label": "User",
  "Type": "UserInDB"
}
```

## RoleType.ClaimsToRole

This type is used when a user's claims are employed to determine the user's role. Claims are pieces of information about the user that are embedded in the authentication token and are typically used for authorization purposes. If the role requires a claim and that particular claim is included in the user's claims, then the role specified in the label is assigned.

```json
{
  "Label": "Admin",
  "Type": "ClaimsToRole",
  "RequireClaim": {
    "Type": "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
    "AllowedValues": [ "S-1-5-21-3284204050-131030045-1404716486-853112" ]
  }
}
```

In this example:

- `RequireClaim` is an object that specifies what claim needs to be present in the user's authentication token for this role to be assigned. In this instance:

   - `"Type": "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid"`: Specifies the type of claim we're looking for in the user's authentication token.
   
   - `"AllowedValues": [ "S-1-5-21-3284204050-131030045-1404716486-853112" ]`: The array represents the acceptable values for the claim. If the user's claim value matches "S-1-5-21-3284204050-131030045-1404716486-853112", the user will be assigned the 'Admin' role.


## RoleType.Ldap

This role type is related to authentication via an LDAP directory. If the role is defined as 'Ldap' and if the user's Security Identifier (SID) is in the specified LDAP groups, then the role label is returned.
