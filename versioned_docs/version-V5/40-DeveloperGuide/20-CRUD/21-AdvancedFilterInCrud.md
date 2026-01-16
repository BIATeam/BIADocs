---
sidebar_position: 1
---

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
