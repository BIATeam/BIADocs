---
sidebar_position: 1
---

To add an advanced filter in an existing CRUD:

1. Add a filter component in the CRUD Feature
   1. Copy the sites\components\site-filter folder in in [YourFeature]s\components\[YourFeature]-filter
   2. Copy the sites\model\site-advanced-filter.ts in in [YourFeature]s\model\[YourFeature]-advanced-filter.ts
   3. In this files rename Site by [YourFeature]
   4. Adapt the model and html to the business need.

2. In [YourFeature]s\views\[YourFeature]s-index\YourFeature]s-index.component.ts add a function checkHaveAdvancedFilter:
```ts
  checkHaveAdvancedFilter()
  {
    this.haveAdvancedFilter =  [YourFeature]AdvancedFilter.haveFilter(this.crudConfiguration.fieldsConfig.advancedFilter);
  }
  
```

3. in [YourFeature]s\views\[YourFeature]s-index\YourFeature]s-index.component.html:
  replace the beginning :
  ```html
  <div>
    <div>
      <bia-table-header
  ````
  by
  ```html
  <div class="flex flex-row flex-wrap bia-page-remove-margin">
    <app-[YourFeature]-filter *ngIf="showAdvancedFilter"
      (filter)="onFilter($event)"
      (closeFilter)="onCloseFilter()"
      [advancedFilter]="crudConfiguration.fieldsConfig?.advancedFilter"
    ></app-[YourFeature]-filter>
    <div class="flex-grow-1 bia-page-margin">
      <div>
        <bia-table-header
  ```

  And add at the end a closing div
  ```html
  </div>
  ```

