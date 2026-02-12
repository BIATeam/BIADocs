---
sidebar_position: 1
---

# Using different DTOs for List and Form

This guide explains how and why to use separate DTOs for list (table) views and for form (create/edit) views, and lists the concrete changes required on both backend and frontend.

## Why do this?

- List DTOs are optimized for display and performance (smaller payloads, formatted fields, aggregated values).
- Form DTOs are optimized for editing (complete/nested data, shape suited to validation and binding).
- Separating the two reduces coupling between table and form concerns, improves list load performance, and keeps mapping and validation logic explicit and testable.

## Backend

### Creating a second DTO

Create two DTO types: one optimized for list display and one for forms. You can reuse your existing DTO as either `ListDto` or `FormDto` and add the second one.

Guidance:

- `ListDto`: include only fields required for the table (IDs, summary fields, pre-formatted values). Keep payloads small for performance.
- `FormDto`: include all fields required for create/edit operations, nested structures and any validation-related shapes.

### Creating a second mapper

Add a mapper for the new DTO. The existing mapper can be duplicated and adapted.

Checklist when adapting the mapper:

- Update generic types (e.g. `DtoToEntity`, `EntityToDto`, `DtoToCellMapping`, `MapEntityKeysInDto`).
- Adjust header/column names to match `ListDto` properties where applicable.
- Adapt mapping logic for fields that differ between `Entity`, `ListDto` and `FormDto`.

### Changing your AppService

Update the service layer to support both DTOs:

- Change the base class from `CrudAppServiceBase` to `CrudAppServiceListAndItemBase`.
  - This base takes additional generics: `FormDto`, `ListDto`, `Entity`, `TKey`, `FilterType`, `FormMapper`, `ListMapper`.
- Update the service interface to extend `ICrudAppServiceListAndItemBase` instead of `ICrudAppServiceBase`.
  - Adjust generic type parameters accordingly.

## Frontend

### Creating a second DTO

Create corresponding DTOs in the frontend models and separate `CrudConfig` instances for list and form views. Each `CrudConfig` defines the `fieldsConfig` for its DTO.

Example:

```typescript
export const featureListCRUDConfiguration: CrudConfig<ListDto> = new CrudConfig({
   ...
   fieldsConfig: featureListFieldsConfiguration,
   ...
})

export const featureFormCRUDConfiguration: CrudConfig<FormDto> = new CrudConfig({
  ...
  fieldsConfig: featureFormFieldsConfiguration,
  ...
})
```

Notes:

- Disable `useCalcMode` and `useImport` on the list `CrudConfig` if those apply only to forms.
- Ensure the module routing uses `featureListCRUDConfiguration` for index/table routes and `featureFormCRUDConfiguration` for read/edit/new routes.
  After that, check that your **feature.module** routing correctly uses the featureListCRUDConfiguration and not the featureFormCRUDConfiguration for routing behavior.

### Services

Update service classes to include both DTO types in their generics.

```typescript
export class FeatureService extends CrudItemService<ListDto, FormDto>
```

```typescript
export class FeatureDas extends AbstractDas<ListDto, FormDto>
```

```typescript
export class FeatureService extends CrudItemService<ListDto, FormDto>
```

```typescript
export class FeatureDas extends AbstractDas<ListDto, FormDto>
```

### Store

State and reducer changes:

```typescript
export interface State extends CrudState<FormDto>, EntityState<ListDto> {}
```

Checklist:

- Use `ListDto` for the `EntityState` and adapter (`createEntityAdapter<ListDto>()`).
- Keep `currentItem` and form-related state as `FormDto`.
- `loadAllByPostSuccess` (list-loading success) should carry `ListDto` items; actions that set or update the current item should use `FormDto`.
- Effects that fetch lists should map to `ListDto`; effects that load single items for edit/read should map to `FormDto`.

### Components

Component changes:

```typescript
export class FeaturesIndexComponent extends CrudItemsIndexComponent<
  ListDto,
  FormDto
> {}

export class FeaturesTableComponent extends CrudItemTableComponent<
  ListDto,
  FormDto
> {}
```

Checklist:

- Ensure index/table components use the list `CrudConfig`.
- Use `FormDto` in item, read, edit and new components and their `CrudConfig`.
- Remove the import component and its route since it is not compatible with the split DTO approach.
