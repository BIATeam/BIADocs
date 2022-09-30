---
layout: default
title: Add advanced filter in CRUD
parent: Create a CRUD
grand_parent: Front
nav_order: 10
---



Add a filter component ex : see site-filter.component 


In Index add a function checkHaveAdvancedFilter:
```ts
  checkHaveAdvancedFilter()
  {
    this.haveAdvancedFilter =  SiteAdvancedFilter.haveFilter(this.crudConfiguration.fieldsConfig.advancedFilter);
  }
  
```

in Index html:
1- after <div fxLayout fxLayout.xs="column" fxLayoutWrap="wrap"> add:
 ```html
  <app-site-filter *ngIf="showAdvancedFilter"
    [fxFlexValue]="25"
    (filter)="onFilter($event)"
    (closeFilter)="onCloseFilter()"
    [advancedFilter]="crudConfiguration.fieldsConfig?.advancedFilter"
  ></app-site-filter>
 ````
2- in bia-table-header tag add
 ```html
    <bia-table-header
...
      [showBtnFilter]="true"
      [showFilter]="showAdvancedFilter"
      [haveFilter]="haveAdvancedFilter"
      (openFilter)="onOpenFilter()"
    >
 ```

Add in model folder the advanced filter object ex for site:
```ts
export class SiteAdvancedFilter {
  userId: number;

  static haveFilter(filter: SiteAdvancedFilter) : boolean{
    return filter?.userId != null
  }
}
```
