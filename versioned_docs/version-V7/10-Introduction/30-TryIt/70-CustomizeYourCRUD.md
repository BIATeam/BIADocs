# Feature Component Customization — MyFeature approach

This document explains how to customize columns and forms for a standard feature.

Short summary of the pattern

- The BIA Toolkit generates a generic feature that wires to the shared UI (table/form) components.
- To customize UI structure (columns, validators, form layout) prefer changing the feature's configuration (`BiaFieldConfig` / `BiaFormLayoutConfig`).
- For non-configurable behaviors (custom cell components, nested editors) add small presentational components under the feature and optionally a thin feature component that extends the framework base (e.g., `MyFeatureTableComponent extends CrudItemTableComponent`).

Why this matters

- You rarely edit the shared table or form templates. The recommended approach is configuration-driven customization inside the feature (folder `src/app/features/my-features/`). The `*-specific` folder in this repo is an example of how to implement custom UI, not a required pattern to copy.

Files to look at (MyFeature example)

- `src/app/features/my-features/model/my-feature.ts` — `myFeatureFieldsConfiguration` holds column definitions and flags (visibility, freezing, icons, minWidth, filters, etc.).
- `src/app/features/my-features/components/my-feature-table/my-feature-table.component.ts` — small class that may extend `CrudItemTableComponent` and uses the shared `bia-calc-table` template.
- `src/app/features/my-features/components/my-feature-form/my-feature-form.component.ts` — may extend `CrudItemFormComponent` and adapt nested child tables and compute visible columns.

## 1) Customize columns: edit the `BiaFieldConfig` entries

Open: `src/app/features/my-features/model/my-feature.ts`.

Key properties on `BiaFieldConfig` that control object fields:
- `type` (PropType): data type for the field.
- `filterMode` (PrimeNGFiltering): type of filtering for the global search on this column.
- `isSearchable` (bool): whether the field can be filtered.
- `isSortable` (bool): whether the field can be sorted by the user with a click on the column header.
- `icon` (string): display an icon instead of label on the header of the column.
- `isEditable` (bool): whether the field can always be edited in the form. Default **true** unless set to **false**.
- `isOnlyInitializable` (bool): whether the field can be edited in the form when creating a new element only. Default **false** unless set to **true**.
- `isOnlyUpdatable` (bool): whether the field can be edited in the form when editing an existing element only. Default **false** unless set to **true**.
- `isEditableChoice` (bool): whether the OneToMany value can be a free string not contained in the options.
- `isVisible` (bool): whether the field should appear in the form. Default **true** unless set to **false**.
- `isHideByDefault` (bool): when true the field is available but hidden by default (user can show it from column toggles). Default **false** unless set to **true**.
- `maxlength` (number): max length for a string type field.
- `searchPlaceholder` (string): placeholder of the filter input for the field. Can be an i18n key.
- `isRequired` (bool): whether the field should be required in form. Default **false** unless set to **true**.
- `validators` (ValidatorFn[]): List of validators for the field. Required field validator is managed through isRequired field and should not appear in this list.
- `specificOutput` / `specificInput` (bool): indicates the field has a different renderer/editor; the shared table/form will use specific template hooks.
- `minWidth`, `maxWidth`: control sizing of field column in table.
- `isFrozen` (bool): freeze column.
- `alignFrozen` (string): Position of the frozen column. Default **left** unless set to **right**.
- `displayFormat` (BiaFieldNumberFormat | BiaFieldDateFormat): Define the display format of the field (only if type is **Number**, **Date**, **DateTime**, **Time**, **TimeOnly** or **TimeSecOnly**).
- `maxConstraints` (number): max number of filter constraints allowed for the field. Default **10**.
- `isVisibleInTable` (bool): whether the field should appear in the table. Default **true** unless set to **false**.
- `filterWithDisplay` (bool): whether the ManyToMany field should be filtered with the display value instead of the id. Default **false** unless set to **true**.
- `multiline` (BiaFieldMultilineString): define the multiline configuration for a string type input in the form. Default **undefined** implies a mono line input.
  
Example (generic snippet you can adapt in `my-feature.ts`):

```ts
Object.assign(new BiaFieldConfig('code', 'myFeature.code'), {
  isRequired: true,
  isFrozen: true,
  minWidth: '50px',
  maxConstraints: 5,
});

Object.assign(new BiaFieldConfig('isActive', 'myFeature.isActive'), {
  isSearchable: false,
  specificOutput: true,
  specificInput: true,
  type: PropType.Boolean,
  icon: PrimeIcons.POWER_OFF,
  minWidth: '50px',
});

Object.assign(new BiaFieldConfig('syncTime', 'myFeature.syncTime'), {
  isHideByDefault: true,
  type: PropType.TimeSecOnly,
  minWidth: '50px',
});
```

How the table uses this config

- The feature table component (e.g., `MyFeatureTableComponent`) extends `CrudItemTableComponent`, which uses `this.configuration.columns` (passed from the feature's `CrudConfig`) to build the UI. The shared template renders a column for each `column` where `isVisibleInTable` is true and not `isHideByDefault` (unless the user or the current view toggles it).
- To change default visible columns: edit the `isHideByDefault` flag or `isVisibleInTable` in the `myFeatureFieldsConfiguration` in the feature model.

When to implement a specific renderer

- If you need a custom cell template (icons, badges, complex HTML, nested components), set `specificOutput: true` on the field and implement the appropriate `ng-template` in the shared template or add a small presentational component and hook it via the feature table component.

Example of a specific output template for bia-table and/or app-my-feature-table in the my-feature-index.component.html:
```html
  <ng-template pTemplate="specificOutput" let-field="field" let-data="data">
    @switch (field.field) {
      <!-- isActive -->
      @case ('isActive') {
        <i
          class="pi pi-circle-fill"
          [ngClass]="{
            'is-not-active': !data,
            'is-active': !!data,
          }"></i>
      }
    }
  </ng-template>
```

## 2) Customize table behavior (actions, frozen columns, column toggles)

- Use `isFrozen` to freeze columns (first columns marked frozen appear fixed).
- Use `specificOutput` to show a custom template; the shared `bia-calc-table` checks field flags and will render specialized templates when present.
- For row actions, the feature `Index` component (e.g., `MyFeatureIndexComponent`) holds `selectionActionsMenuItems` and wiring for buttons. You can add actions there which call methods on the feature service.

## 3) Customize forms: update `BiaFormLayoutConfig` or implement `MyFeatureFormComponent`

- The generated form layout is driven by a `myFeatureFormLayoutConfiguration` (`BiaFormLayoutConfig`) in the model. Edit that to change grouping, rows and order of fields. This supports the specificInput templates for your more complicated fields. See the documentation of the Form Layout Configuration here : [Form Configuration](../../40-DeveloperGuide/20-CRUD/70-FormConfiguration.md)
- If you still can't do what you need to with these options, you can create a form from scratch instead of using the bia-form.

## 4) Best practices (MyFeature)

- Prefer configuration first: change `myFeatureFieldsConfiguration` in `src/app/features/my-features/model/my-feature.ts`.
- Use `specificOutput`/`specificInput` flags to indicate custom rendering; keep templates small and reusable.
- Put custom UI logic in light-weight presentational components under `src/app/features/my-features/components/` and call them from the shared table/form templates via `ng-template` or via the feature table/form component that extends the shared class.

