---
layout: default
title: Create a CRUD (front)
parent: Front
grand_parent: Developer guide
nav_order: 20
---

# Create a CRUD (front)
This document explains how to quickly create a CRUD module feature universal.
It means that you can switch this functionnalities:
- Navigation in Page mode / Popup Mode
- Use view / Not use view
- Modification in the table / in dedicated form 
- Refresh with SignalR / not use signalR
  
<u>For this example, we imagine that we want to create a new feature with the name: <span style="background-color:#327f00">aircraft-type</span>.   </u>

## Prerequisite
It is strongly recommended to generate front-end CRUD in same time of [back-end](../40-Back/70-CreateACRUD.md) CRUD.
The back-end is ready, i.e. steps before paragraph 3 are already done.

## Generate new feature
Use the BIAToolKit on [CRUD Generation](../50-BIAToolKit/50-CreateCRUD.md) tab with (at least) _'Front'_ (for generation) and _'CRUD'_ (for Generation Type) checkboxes checked (and Generation _'WebApi'_ recommanded).<br>
Don't forget to fill new crud name on singular (i.e. <span style="background-color:#327f00">aircraft-type</span>) and plural form (i.e. <span style="background-color:#327f00">aircrafts-types</span>).<br>
After parsing, it is necessary to choose 'Display item name'.

If you want to **link existing options** to the crud, choose option (1 or more) in combobox 'Option item'.


<u>After generation don't forget to :</u>

- ### Update navigation
Open the file **src\app\shared\navigation.ts** and in the array **NAVIGATION**, update *path* like this 
```typescript
{
  labelKey: 'app.aircraftsTypes',
  permissions: [Permission.AircraftType_List_Access],
  path: ['/aircrafts-types']
}
```

- ### Update translations
1. Open the file **src\assets\i18n\app\en.json** and:<br> 

add in `"app"`
``` json
"app": {
    ...
    "aircraftsType": "Aircrafts types"
  }
```
add 
``` json
"aircraftType": {
  "add": "Add aircraft type",
  "edit": "Edit aircraft type",
  "listOf": "List of aircrafts types"
  }
```
and add translations of interface properties.

2. Open the file **src\assets\i18n\app\fr.json** and:<br>

add in `"app"`
``` json
"app": {
    ...
    "aircraftsType": "Type d'aéronefs"
  }
```
add
``` json
"aircraftType": {
    "add": "Ajouter type d'aéronef",
    "edit": "Modifier type d'aéronef",
    "listOf": "Liste des types d'aéronefs"
  }
```
and add translations of interface properties.

3. Open the file **src\assets\i18n\app\es.json** and:<br>

add in `"app"`
``` json
"app": {
    ...
    "aircraftsType": "Aeronaves"
  }
```
add
``` json
"aircraftType": {
   "add": "Añadir tipo de aeronave",
    "edit": "Editar tipo de aeronave",
    "listOf": "Lista de tipos de aeronaves"
  }
```
and add translations of interface properties.

When you have finished adding translations, use this site to sort your json:
https://novicelab.org/jsonabc/


## Relation to Option
### Universal Mode
* In universal mode the loading of the relations are done in **...-options-service.ts**
* Adapt the lists to display in combo box in :
  * the members of the classe, 
  * the constructor 
  * the function loadAllOptions.
* The list should be OptionDto list in domain. See [this page](30-CreateAnOption.md) to create the domain feature option.

## Enable Views
* Just change the variable useView = false; to useView = true; in the **...constants.ts**.

## Enable SignalR:
* Just change the variable useSignalR = false; to useSignalR = true; in the **...constants.ts**.

## Spreadsheet mode
* Just change the variable useCalcMode = false; to useCalcMode = true; in the **...constants.ts**.
  
## Bulk mode
* Just change variables useInsert/useUpdate/useDelete = false; to useInsert/useUpdate/useDelete = true; in the **...constants.ts** (in bulkMode part).

## Specific Input and Output
### Since V3.7.0
* You can see an exemple in BIADemo with the Crud 'planes-specific'
  * In **views/...-index.component.ts**
    * Add the function onChange at the end of the file
  ```ts
    onChange() {
      this.aircraftTableComponent.onChange();
    }
  ```
    * In function initTableConfiguration() add the flag (specificOutput: true and\or specificInput:true) on field where you want to use a specific input (for calc mode only) or output (=read only)
  * In **views/...-index.component.html** 
    * for non calc mode add the template specificOutput in bia-table
    ```html
      <bia-table
        ...
      >
        <ng-template pTemplate="specificOutput" let-col="col" let-rowData="rowData">
          <ng-container [ngSwitch]="col.field">
            <ng-container *ngSwitchCase="'isActive'">
              <i class="pi pi-circle-fill" [style]="'color: ' + (rowData[col.field]?'green':'red')"></i>
            </ng-container> <!-- isActive -->
            <ng-container *ngSwitchCase="'capacity'">
              <ng-container *ngIf="rowData[col.field] < 0">
                - Negative -
              </ng-container>
              <ng-container *ngIf="rowData[col.field] === 0">
                0 Empty 0
              </ng-container>
              <ng-container *ngIf="rowData[col.field] > 0 && rowData[col.field] < 10">
                + Small +
              </ng-container>
              <ng-container *ngIf="rowData[col.field] >= 10 && rowData[col.field] < 100">
                ++ Medium ++
              </ng-container>
              <ng-container *ngIf="rowData[col.field] >= 100">
                +++ Large +++
              </ng-container>
            </ng-container> <!-- capacity -->
          </ng-container>
        </ng-template>
      </bia-table>
    ```

    * for Calc mode add the template specificInput and\or specificOutput in app-aircraft-table
    ```html
      <app-aircraft-table
        ...
      >
        <ng-template pTemplate="specificOutput" let-col="col" let-rowData="rowData">
          <ng-container [ngSwitch]="col.field">
            <ng-container *ngSwitchCase="'isActive'">
              <i class="pi pi-circle-fill" [style]="'color: ' + (rowData[col.field]?'green':'red')"></i>
            </ng-container> <!-- isActive -->
            <ng-container *ngSwitchCase="'capacity'">
              <ng-container *ngIf="rowData[col.field] < 0">
                - Negative -
              </ng-container>
              <ng-container *ngIf="rowData[col.field] === 0">
                0 Empty 0
              </ng-container>
              <ng-container *ngIf="rowData[col.field] > 0 && rowData[col.field] < 10">
                + Small +
              </ng-container>
              <ng-container *ngIf="rowData[col.field] >= 10 && rowData[col.field] < 100">
                ++ Medium ++
              </ng-container>
              <ng-container *ngIf="rowData[col.field] >= 100">
                +++ Large +++
              </ng-container>
            </ng-container> <!-- capacity -->
          </ng-container>
        </ng-template>
        <ng-template pTemplate="specificInput" let-field="field" let-form="form">
          <div [formGroup]="form">
            <ng-container [ngSwitch]="field.field">
              <ng-container *ngSwitchCase="'isActive'">
                <p-checkbox [binary]="true" [formControlName]="field.field" (onChange)="onChange()"></p-checkbox>
              </ng-container> <!-- isActive -->
              <ng-container *ngSwitchCase="'capacity'">
                <input pInputText type="number" [formControlName]="field.field" (change)="onChange()" />
              </ng-container> <!-- capacity -->
            </ng-container>
          </div>
        </ng-template>
      </app-aircraft-table>
    ```



### Before V3.7.0 the procedure was only for Specific Input:
For specific properties that are not managed by the Framework, your table component must have an html. In this html, you have to copy/paste the content of the html from **bia-calc-table.component.html**.

In this html, you must add your components in the **SPECIFIC INPUT** zone and **SPECIFIC OUTPUT** zone.

```html
<!-- Begin Add here specific input -->
<!-- End Add here specific input -->
...
<!-- Begin Add here specific output -->
<!-- End Add here specific output -->
```

in your typescript file, you must fill the **specificInputs** property.

``` typescript
specificInputs: string[] = [
    'potting',
    'locking',
    ...
  ];
```
