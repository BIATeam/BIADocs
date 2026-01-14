---
title: Troubleshooting V5
---

# Troubleshooting on the known issues in the Framework V5

## BIAToolkit Option/DTO/CRUD generator with inherited properties
When using BIAToolkit to generate Option, DTO or CRUD with V5 project, the inherited properties from BIA.Net.Core base objects or from your own classes (ex: Id, RowVersion...) will not be available into the Toolkit when choosing your mapping properties.  

You must then : 
1. Declare into your target entity the missing properties that you need, even if it's a duplicate of the inherited ones
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

This bug is fixed in V5.2.2.

## Calc mode closing when navigating from multiselect to another multiselect

During calc mode edit or new, opening a multiselect while closing another multiselect happens is a wrong order, registering the opening of the new multiselect and then the closing of the previous multiselect. The form then thinks it isn't currently working on a complexinput and when another click happens in the multiselect overlay, the form considers the user is leaving the form and validates it.

To fix the problem, we need to let the closing of the previous multiselect register before registering the opening.

To fix it, you need to edit the file **bia-calc-table.component.ts**, function ***onComplexInput*** like that:

Current version:
```ts
  public onComplexInput(isIn: boolean) {
    if (isIn) {
      this.isInComplexInput = true;
      this.currentRow = this.getParentComponent(
        document.activeElement,
        'bia-selectable-row'
      ) as HTMLElement;
      this.currentInput = document.activeElement as HTMLElement;
    }
    ...
  }
```

Fixed version:
```ts
  public onComplexInput(isIn: boolean) {
    if (isIn) {
      setTimeout(() => {
        this.isInComplexInput = true;
        this.currentRow = this.getParentComponent(
          document.activeElement,
          'bia-selectable-row'
        ) as HTMLElement;
        this.currentInput = document.activeElement as HTMLElement;
      });
    }
    ...
  }
```

This bug is fixed in V5.2.2.

## Cloning CRUD items feature

DynamicLayout is necessary in V5+ of the framework if you want to use the clone feature for your CRUD items.

You need to update your module file to use DynamicLayoutComponent by using this script on your project:

Download the [migration script](../Scripts/Migrate_to_DynamicLayout.ps1) ([.txt - Save link as](../Scripts/Migrate_to_DynamicLayout.txt)), then :
- change source path of the migration script to target your project root and your Angular project
- run it for each of your Angular project (change the Angular source path each time)

Documentation for DynamicLayout can be found [here](../40-DeveloperGuide/20-CRUD/05-DynamicLayout.md)