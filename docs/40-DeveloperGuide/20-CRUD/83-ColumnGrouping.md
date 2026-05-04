---
sidebar_position: 1
---

# Column Grouping in BIA Tables

Column grouping lets you display a multi-row header where one or more columns share a common parent header cell. It works with both `bia-table` and `bia-calc-table`.

## How it works

The grouping is driven entirely by the `columnGroup` property on `BiaFieldsConfig`. No changes are needed in the HTML or the table component itself.

When `columnGroup` is defined:
- The table renders one header row per entry in `rows`, followed by a final leaf row for the grouped columns.
- Columns that are **not** part of any group span all header rows via `rowspan`.
- Columns that **are** grouped appear only in the leaf row, under their parent group cell.

## Data model

```ts
// packages/bia-ng/models/bia-column-group-config.ts

export interface BiaColumnGroupCell {
  header: string;      // translation key for the group label
  fieldKeys: string[]; // fields covered by this group cell
}

export interface BiaColumnGroupConfig {
  rows: BiaColumnGroupCell[][]; // one entry per group header row
}
```

`BiaFieldsConfig` exposes it as an optional property:

```ts
export interface BiaFieldsConfig<TDto> {
  columns: BiaFieldConfig<TDto>[];
  formValidators?: ValidatorFn[];
  advancedFilter?: any;
  columnGroup?: BiaColumnGroupConfig;  // <-- add this
}
```

## Basic example

The following produces a two-level header where `departureAirport` and `arrivalAirport` are grouped under a single "Airport" cell.

```
┌──────────────────────────────────────────┐
│  id  │         Airport                   │
│      ├──────────────────┬────────────────┤
│      │ departureAirport │ arrivalAirport │
└──────────────────────────────────────────┘
```

```ts
// flight.ts
export const flightFieldsConfiguration: BiaFieldsConfig<Flight> = {
  columns: [
    Object.assign(new BiaFieldConfig('id', 'flight.id'), {
      type: PropType.String,
    }),
    Object.assign(new BiaFieldConfig('departureAirport', 'flight.departureAirport'), {
      type: PropType.OneToMany,
    }),
    Object.assign(new BiaFieldConfig('arrivalAirport', 'flight.arrivalAirport'), {
      type: PropType.OneToMany,
    }),
  ],
  columnGroup: {
    rows: [
      [
        {
          header: 'flight.groupAirport',   // i18n key
          fieldKeys: ['departureAirport', 'arrivalAirport'],
        },
      ],
    ],
  },
};
```

Add the translation key in your i18n files:

```json
// en.json
{
  "flight": {
    "groupAirport": "Airport"
  }
}
```

## Multiple group rows

`rows` is an array, so you can stack several levels of grouping. Each entry in `rows` produces one header row. The leaf row (containing the actual column headers) is always appended automatically.

```
┌──────────────────────────────────────────────────────────┐
│  id  │                   Location                        │
│      ├──────────────────────────┬─────────────────────── │
│      │       Departure          │       Arrival          │
│      ├──────────────┬───────────┼──────────────┬──────── │
│      │    airport   │    city   │    airport   │  city   │
└──────────────────────────────────────────────────────────┘
```

```ts
columnGroup: {
  rows: [
    // row 1 — top level
    [
      {
        header: 'flight.groupLocation',
        fieldKeys: ['departureAirport', 'departureCity', 'arrivalAirport', 'arrivalCity'],
      },
    ],
    // row 2 — second level
    [
      {
        header: 'flight.groupDeparture',
        fieldKeys: ['departureAirport', 'departureCity'],
      },
      {
        header: 'flight.groupArrival',
        fieldKeys: ['arrivalAirport', 'arrivalCity'],
      },
    ],
  ],
},
```

## Rules and constraints

| Rule | Detail |
|---|---|
| Field order matters | Group cells are rendered in the order their `fieldKeys` appear in `displayedColumns`. Keep `fieldKeys` in the same order as `columns`. |
| Ungrouped columns span all rows | Any column not referenced in any `fieldKeys` automatically gets a `rowspan` covering all group rows + the leaf row. |
| Column reordering is disabled | When `columnGroup` is set, `[reorderableColumns]` is automatically forced to `false` on the table. |
| Hidden columns are handled | If a column is hidden (not in `displayedColumns`), its `fieldKeys` entry is simply skipped — the group `colspan` adjusts accordingly. |
| `fieldKeys` must match `BiaFieldConfig.field` | The strings in `fieldKeys` must exactly match the `field` property of the corresponding `BiaFieldConfig`. |

## Checklist

1. Add `columnGroup` to your `BiaFieldsConfig` constant.
2. List every grouped field in `fieldKeys` in the same order they appear in `columns`.
3. Add the i18n translation key for each `header`.
4. Nothing to change in the table component or its HTML.
