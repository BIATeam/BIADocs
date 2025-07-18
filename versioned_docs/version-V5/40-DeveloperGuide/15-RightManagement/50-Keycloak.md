---
sidebar_position: 1
---

# Keycloak authentication

This file explains the Keycloak authentication.
As a prerequisite, you must have configured a Keycloak, see the tutorial in **Setup environment**

## Overview

The application is secured via a JWT generated by the backend. But before its generation, a first authentication is necessary: either Windows, or via a JWT provided by Keycloak. In previous versions of BIA framework (< 3.8), windows authentication was used. we will see here via Keycloak.

## Add Credential
The BIA application uses a service account to retrieve data from KeyCloak (See Setup Environment, Keycloak, **Service Account** section)

If the application is running on Windows, add the login password in the vault via this command (By adapting the UserName and the UserPassword):

``` cmd
%windir%\system32\cmdkey.exe /generic:BIA:KeycloakSearchUserAccount /user:"UserName" /pass:"UserPassword"
```

## How Activate

You must have at least version 3.8 of the BIA framework.

### Back End

On your web server, disable windows authentication for your back end application.

At the source code level, in the **launchSettings.json** file, Change these settings as follows:

```json
{
  "iisSettings": {
    "windowsAuthentication": false,
    "anonymousAuthentication": true,
    ...
  },
}
```


Add the Keycloak configuration in your different files **bianetconfig.XXX.json**

Values are to be adapted according to your Keycloak.
In this example of json, the realm is called BIA-Realm, the client is called biaapp

```json
"Authentication": {
      "Keycloak": {
        "IsActive": true,
        "BaseUrl": "https://url_of_my_keycloak", // To be adapted according to your Keycloak
        "Configuration": {
          "realm": "BIA-Realm",
          "Authority": "/realms/BIA-Realm",
          "RequireHttpsMetadata": true,
          "ValidAudience": "account"
        },
        "Api": {
          "TokenConf": {
            "RelativeUrl": "/realms/BIA-Realm/protocol/openid-connect/token",
            "ClientId": "biaapp",
            "GrantType": "password",
            "CredentialKeyInWindowsVault": "BIA:KeycloakSearchUserAccount",
            "EnvServiceAccountUserName": "KC_SA_USERNAME",
            "EnvServiceAccountPassword": "KC_SA_PASSWORD"
          },
          "SearchUserRelativeUrl": "/admin/realms/BIA-Realm/users"
        }
      },
      ...
}
```

The login and password of the keycloak account that owns the role **view-users** must be registered in the vault via this command while connected with the application pool account:

```bat
%windir%\system32\cmdkey.exe /generic:BIA:KeycloakSearchUserAccount /user:"MyLogin" /pass:"MyPassword"
```

## Offline JWT Verification

In certain deployment scenarios, the application server might not have direct access to the Keycloak server to validate JWT tokens. In such cases, you can configure the application to verify JWT tokens offline using Keycloak's public key.

### Overview

This approach allows the application to validate JWT tokens without making real-time requests to Keycloak. The application downloads the public key from Keycloak and uses it to verify the token signature locally.

### Configuration Steps

#### 1. Download the Public Key

First, you need to download the public key from your Keycloak server. The public key is available at the following URL:

```
https://[KEYCLOAK_URL]/realms/[REALM_NAME]/protocol/openid-connect/certs
```

For example:
```
https://mykeycloak.mycompany/realms/BIA-Realm/protocol/openid-connect/certs
```

This endpoint returns a JSON Web Key Set (JWKS) containing the public keys used to verify JWT tokens.

#### 2. Create the Certificate File

Save the downloaded JSON response to a file named `keycloakcerts.[ENV].json` in the same directory as your other configuration files (e.g., `bianetconfig.XXX.json`).

Example file name: `keycloakcerts.DMEUEXT_INT.json`

The content should look like this:

```json
{
  "keys": [
    {
      "kid": "key-id",
      "kty": "RSA",
      "use": "sig",
      "n": "base64-encoded-modulus",
      "e": "AQAB",
      "x5c": [
        "certificate-data"
      ],
      "x5t": "thumbprint",
      "alg": "RS256"
    }
  ]
}
```

#### 3. Update Configuration

Modify your `bianetconfig.XXX.json` file to include the `CertFileName` parameter in the Keycloak configuration:

```json
"Authentication": {
  "Keycloak": {
    "IsActive": true,
    "BaseUrl": "https://url_of_my_keycloak",
    "Configuration": {
      "realm": "BIA-Realm",
      "Authority": "/realms/BIA-Realm",
      "RequireHttpsMetadata": true,
      "ValidAudience": "account",
      "CertFileName": "keycloakcerts.PRD.json"
    },
...
  }
}
```

## How Restore Windows Authentication

### Back End

On your web server, enable windows authentication for your back end application.

At the source code level, in the **launchSettings.json** file, Change these settings as follows:

```json
{
  "iisSettings": {
    "windowsAuthentication": true,
    "anonymousAuthentication": true,
    ...
  },
}
```


In your different files **bianetconfig.XXX.json**, set the **IsActive** param to **false**.

```json
"Authentication": {
      "Keycloak": {
        "IsActive": false,
        ...
      },
      ...
}