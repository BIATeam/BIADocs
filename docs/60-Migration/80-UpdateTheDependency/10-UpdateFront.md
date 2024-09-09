---
sidebar_position: 1
---

This upgrade in to apply only on **BIADemo project**.
Other project should be upgrade with the BIAToolKit and following the Migration process describe in the [Migration Page](../MIGRATION.md).


Migration BIADemo Angular version:
- The reference is [Angular Update Guide](https://update.angular.io/)
- But change the update @angular... to match with targeted version and to specify all package that required to be update :
  - check keycloak-angular and keycloak-js corresponding version : [Keycloak Angular](https://www.npmjs.com/package/keycloak-angular)
  - check the TypeScript and RxJS corresponding version : [NgRx - V16 Update Guide](https://ngrx.io/guide/migration/v16)
  - check corresponding version for ngx-translate: (ngx-translate/core)[https://github.com/ngx-translate/core]
  - check recommendation on [PrimeNg Update Guide](https://github.com/primefaces/primeng/wiki/Migration-Guide)
  - commit all change
  - perform an npm install (npm i)
  - and launch the update command with all package 
    (example for Angular 14):
    ```cmd
    ng update @angular/cli@14 @angular/animations@14 @angular/cdk@14 @angular/common@14 @angular/compiler@14 @angular/core@14 @angular/forms@14 @angular/platform-browser@14 @angular/platform-browser-dynamic@14 @angular/router@14 @angular/service-worker@14 @ngrx/effects@14 @ngrx/entity@14 @ngrx/store@14 @ngx-translate/core@14 keycloak-angular@12 keycloak-js@19 primeng@14 @angular-eslint/schematics@14
    ```
    (example for Angular 15):
    ```cmd
    ng update @angular/cli@15 @angular/animations@15 @angular/cdk@15 @angular/common@15 @angular/compiler@15 @angular/core@15 @angular/forms@15 @angular/platform-browser@15 @angular/platform-browser-dynamic@15 @angular/router@15 @angular/service-worker@15 @ngrx/effects@15 @ngrx/entity@15 @ngrx/store@15 @ngx-translate/core@14 keycloak-angular@13 keycloak-js@21 primeng@15 @angular-eslint/schematics@15 typescript@4.8.4 
    ng update rxjs@7.5 
    ng update @type/node@16
    ```
    (example for Angular 16):
    ```cmd
    ng update @angular/cli@16 @angular/animations@16 @angular/cdk@16 @angular/common@16 @angular/compiler@16 @angular/core@16 @angular/forms@16 @angular/platform-browser@16 @angular/platform-browser-dynamic@16 @angular/router@16 @angular/service-worker@16 @ngrx/effects@16 @ngrx/entity@16 @ngrx/store@16 @ngx-translate/core@15 keycloak-angular@14 keycloak-js@21 primeng@16 @angular-eslint/schematics@16 typescript@5 

    ```
Finalize with the update of the theme if required:
•	https://biateam.github.io/BIADocs/docs/40-DeveloperGuide/30-Front/40-CustomizePrimeNGTheme.html



