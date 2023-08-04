---
layout: default
title: Update front
parent: Update the dependencies
nav_order: 10
---

This upgrade in to apply only on **BIADemo project**.
Other project should be upgrade with the BIAToolKit and following the Migration procces descript in the [Migration Page](../MIGRATION.md).


Migration BIADemo Angular version:
- The reference is [Angular Update Guide](https://update.angular.io/)
- But change the update @angular... to match with targeted version and to specify all package that requiered to be update :
  - check keycloak-angular and keycloak-js corresponding version : https://www.npmjs.com/package/keycloak-angular
  - check the TypeScript and RxJS corresponding version : https://ngrx.io/guide/migration/
  - check recomandation on [PrimeNg Update Guide](https://github.com/primefaces/primeng/wiki/Migration-Guide)
  - commit all change
  - performe an npm install (npm i)
  - and launch the update command with all package (exemple for Angular 14):
    ```
    ng update @angular/cli@14 @angular/animations@14 @angular/cdk@14 @angular/common@14 @angular/compiler@14 @angular/core@14 @angular/forms@14 @angular/platform-browser@14 @angular/platform-browser-dynamic@14 @angular/router@14 @angular/service-worker@14 @ngrx/effects@14 @ngrx/entity@14 @ngrx/store@14 @ngx-translate/core@14 keycloak-angular@12 keycloak-js@19 primeng@14 @angular-eslint/schematics@14
    ```
Finalize with the update of the theme if requiered:
•	https://biateam.github.io/BIADocs/docs/30-DeveloperGuide/30-Front/40-CustomizePrimeNGTheme.html



