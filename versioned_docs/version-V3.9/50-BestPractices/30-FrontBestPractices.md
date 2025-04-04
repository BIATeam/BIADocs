---
sidebar_position: 1
---

# Beginning
This document explains how the rules to respect in the project based on the BIA Angular framework.   

## Before commit
before committing your changes, run the following commands:
For version after or equal V3.9.0:
* npm run clean : if ng lint pop errors. Fix the errors.
For version before V3.9.0:
* ng lint: You must have the following message: "All files pass linting".
* ng build --aot: You must not get an error message.

## File not to be modified
Some files are part of the Framework and should not be modified.

* src/app/core/bia-core
* src/app/shared/bia-shared
* src/assets/bia
* src/scss/bia
* src/app/features/sites
* src/app/features/users

## NPM Package
The content of the framework is normally sufficient for the needs of any project. You should never install any other npm package other than those provided by the Framework.   You should not use the `ng update` command.   
The component library chosen for this framework is [PrimeNG](https://www.primefaces.org/primeng/v9.1.4-lts/). You must use only these components.   
If the content of this framework is not enough, please contact first The BIATeam before installing an npm package on your project.

## Design / Layout
If you need to modify the PrimeNG component design, you can modify the following file: src\scss\\_app-custom-theme.scss   
For example you can change the row/cell size of the tables by changing the following `padding` property:
``` scss
p-table {
  td {
    font-weight: 300;
    padding: 0.414em 0.857em !important;
  }
}
```
For the layout, [angular/flex-layout](https://github.com/angular/flex-layout/wiki) is used. [Here](https://tburleson-layouts-demos.firebaseapp.com/#/docs) is a help site.

## NGRX Store
The framework and management of the store is based on this application. You can follow this example for the implementation of your store:   
[angular-contacts-app-example](https://github.com/avatsaev/angular-contacts-app-example)

