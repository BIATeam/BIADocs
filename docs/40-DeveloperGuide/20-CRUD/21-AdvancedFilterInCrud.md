---
sidebar_position: 1
---

# Advanced Filters in CRUD

## Overview

This guide outlines the steps to implement advanced filtering functionality for a feature using the framework.

---

## Step 1: Define Backend DTO

Create a new domain DTO object:

1. **Advanced Filter DTO** (`MyFeatureAdvancedFilterDto`)
   - Contains filter criteria properties
   - Use nullable types for optional filter fields

---

## Step 2: Update Backend Service Layer

1. **Update the service interface** (`IMyFeatureSpecificAppService`)
   - Change generic parameter from `PagingFilterFormatDto` to `PagingFilterFormatDto<MyFeatureAdvancedFilterDto>`

2. **Implement filter specification in the service** (`MyFeatureAppService`)
   - Override `SetGetRangeFilterSpecifications()` to apply advanced filters
   - Create `GetMyFeatureAdvancedFilterSpecification()` method using the Specification pattern
   - Build LINQ expressions to filter entities based on filter criteria

3. **Update controller endpoints**
   - Change parameter type in `GetAll()` and `GetFile()` endpoints to use the generic filter type

---

## Step 3: Create Frontend Filter DTO

Create the TypeScript DTO (`MyFeatureAdvancedFilterDto`) that mirrors the backend structure:
- Implement a static `hasFilter()` method in the Dto class to check if any filters are active

---

## Step 4: Build the Advanced Filter Component

Create a reusable filter component (`MyFeatureAdvancedFilterComponent`) with:

1. **Component class**
   - Create reactive form with form controls for each filter field
   - Implement `onFilter()` to emit filter object when submitted
   - Implement `ngOnChanges()` to update form when external filters change
   - Use `ViewContainerRef.createEmbeddedView()` to render template outside component tag

2. **Template**
   - Define all the filters needed as form controls
   - Provide Reset and Filter action buttons with loading state

---

## Step 5: Integrate Filter into Index Component

1. **Update component imports and declarations**
   - Import the filter component
   - Override `checkhasAdvancedFilter()` method to update filter state

2. **Update template layout**
   - Reorganize main container to use flexbox row layout
   - Conditionally display filter panel using `@if` control flow
   - Add filter button to table controller
   - Wire up filter events: `(filter)="onFilter($event)"` and `(closeFilter)="onCloseFilter()"`

---

## Extension Pattern

To add more filter criteria:

1. Add new property to `MyFeatureAdvancedFilterDto` (backend and frontend)
2. Add specification logic in `GetMyFeatureAdvancedFilterSpecification()` method
3. Add form control and options list to component class (frontend)
4. Add filter control to template

## Working example
A working example can be found in BIA Demo under [PlaneSpecific feature](https://github.com/BIATeam/BIADemo/tree/develop/Angular/src/app/features/planes-specific)

---

## Alternative for front end part: Using BiaAdvancedFilterComponent

Starting with V8 version of the framework, instead of building a custom filter component from scratch, you can use the generic `BiaAdvancedFilterComponent` driven by a `BiaAdvancedFilterConfig`. This approach requires less boilerplate and is completely independent of `BiaFieldsConfig`.

### Usage

```html
<bia-advanced-filter
  [filterConfig]="filterConfig"
  [hidden]="!showFilter"
  [advancedFilter]="currentFilter"
  (filter)="onFilter($event)"
  (closeFilter)="showFilter = false">
</bia-advanced-filter>
```

### Inputs

| Input | Type | Description |
|---|---|---|
| `filterConfig` | `BiaAdvancedFilterConfig<T>` | Drives which fields are shown and how they are rendered. |
| `advancedFilter` | `T \| null` | Current filter value, patched into the form when it changes. |
| `hidden` | `boolean` | Hides the panel without destroying it. |
| `dictOptionDtos` | `DictOptionDto[]` | Fallback options for `OneToMany`/`ManyToMany` fields, keyed by `field`. Lowest priority — overridden by `options` and `options$` on the field config. |
| `specificInputTemplate` | `TemplateRef` | Custom widget template for fields with `specificInput: true`. Context: `{ fieldConfig, form }`. |

### Outputs

| Output | Payload | Description |
|---|---|---|
| `filter` | `T` | Emitted on form submit with the current filter value. |
| `closeFilter` | `void` | Emitted when the close button is clicked. |

---

### BiaAdvancedFilterConfig

Defined alongside the filter DTO, not inside `BiaFieldsConfig`.

```ts
export const myAdvancedFilterConfig: BiaAdvancedFilterConfig<MyFilterDto> = {
  fields: [
    new BiaAdvancedFilterFieldConfig('status', 'my.status', PropType.OneToMany),
  ],
};
```

### BiaAdvancedFilterFieldConfig

| Property | Type | Description |
|---|---|---|
| `field` | `keyof TAdvancedFilter` | DTO property name. Used as the form control name. |
| `header` | `string` | Translation key for the field label. |
| `type` | `PropType` | Determines the widget rendered (see widget mapping below). |
| `options` | `OptionDto[]` | Static options for `OneToMany`/`ManyToMany` fields. |
| `options$` | `Observable<OptionDto[]>` | Dynamic options from a store selector. Subscribed automatically. |
| `numberFormat` | `BiaFieldNumberFormat` | Number display config. Auto-populated from locale if omitted. |
| `dateFormat` | `BiaFieldDateFormat` | Date display config. Auto-populated from locale if omitted. |
| `allowSelectFilter` | `boolean` | Shows a search box inside the dropdown. |
| `specificInput` | `boolean` | When `true`, renders via `specificInputTemplate` instead of a built-in widget. |

### Widget mapping

| `PropType` | Widget |
|---|---|
| `String`, `Time*` | Text input |
| `Number` | `p-inputNumber` (locale-aware) |
| `Date` | `p-date-picker` |
| `DateTime` | `p-date-picker` with time |
| `Boolean` | Yes/No `p-select` |
| `OneToMany` | `p-select` with `OptionDto` list |
| `ManyToMany` | `p-multiSelect` with `OptionDto` list |

---

### Options sources (priority order)

1. `fieldConfig.options` — static array set at config time
2. `fieldConfig.options$` — observable (e.g. `store.select(getAllPlaneTypeOptions)`), subscribed automatically
3. `dictOptionDtos` input — passed to the component, keyed by `field` name

### Example: static options

```ts
Object.assign(
  new BiaAdvancedFilterFieldConfig(
    'enginesRange',
    'plane.enginesRange.title',
    PropType.OneToMany
  ),
  {
    options: [
      new OptionDto(0, 'plane.enginesRange.zero', DtoState.Unchanged),
      new OptionDto(1, 'plane.enginesRange.oneOrTwo', DtoState.Unchanged),
    ],
  }
);
```

### Example: domain store options

```ts
// In the component constructor
store.dispatch(DomainPlaneTypeOptionsActions.loadAll());

// In the config
Object.assign(
  new BiaAdvancedFilterFieldConfig(
    'planeTypeId',
    'plane.planeType',
    PropType.OneToMany
  ),
  { options$: store.select(getAllPlaneTypeOptions) }
);
```

### Example: custom widget via specificInputTemplate

```ts
// In the config
Object.assign(
  new BiaAdvancedFilterFieldConfig(
    'myCustomField',
    'my.label',
    PropType.String
  ),
  { specificInput: true }
);
```

```html
<bia-advanced-filter
  [filterConfig]="filterConfig"
  [specificInputTemplate]="customTpl"
  ...>
</bia-advanced-filter>

<ng-template #customTpl let-fieldConfig="fieldConfig" let-form="form">
  @if (fieldConfig.field === 'myCustomField') {
    <!-- your custom widget here, bind to form -->
  }
</ng-template>
```