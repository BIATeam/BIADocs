---
title: Troubleshooting V5
---

# Troubleshooting on the known issues in the Framework V5

## BIAToolkit Option/DTO/CRUD generator with inherited properties
When using BIAToolkit to generate Option, DTO or CRUD with V5 project, the inherited properties from BIA.Net.Core base objects or from your own classes (ex: Id, RowVersion...) will not be available into the Toolkit when choosing your mapping properties.  

You must then : 
1. Declare into your target entity the missing properties thtat you need, even if its a duplicate of the inherited ones
2. Create your Option/DTO/CRUD
3. Delete the duplicated properties

## Fix for Keycloak
Update the **initKeycloack** method of **bia-app-init.service.ts**

```ts
protected initKeycloack(appSettings: AppSettings): Observable<AuthInfo> {
    this.initEventKeycloakLogin();
    const obs$: Observable<AuthInfo> = this.initEventKeycloakSuccess();

    this.keycloakService.init({
      config: {
        url: appSettings.keycloak?.baseUrl,
        realm: appSettings.keycloak?.configuration.realm,
        clientId: appSettings.keycloak?.api.tokenConf.clientId,
      },
      enableBearerInterceptor: false,
      initOptions: {
        onLoad: 'check-sso',
        checkLoginIframe: false,
        enableLogging: isDevMode(),
      },
    });

    return obs$;
  }
```
