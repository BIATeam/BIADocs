---
sidebar_position: 1
---

# Local Date/Time in CRUD

This guide explains how to configure a CRUD field so that dates are displayed and edited in the **client's local timezone** instead of UTC.

---

## Overview

### Default behavior (UTC)

By default, BIA stores dates as UTC in the database and transfers them as-is through the API to the frontend. The client always manipulates UTC. This is the correct behavior for:

- Dates that have no timezone meaning (e.g. a contract start date "2024-01-15" that applies everywhere identically).
- Fields typed as `DateTime` / `Date` in the entity and DTO.

### Local date/time mode

When a date carries a **real instant in time** that depends on where the user is (e.g. "meeting at 14:30 in Paris" ≠ "14:30 in Tokyo"), you should activate local date/time mode. This mode:

1. Stores dates as `DateTimeOffset` in the database — the UTC instant is preserved.
2. Displays the value converted to the **client's local timezone** in the table and form.
3. Sends the client's IANA timezone to the backend on every HTTP request so that **filters and sort** work correctly in local time.

:::info Key rule
Use `DateTimeOffset` (backend) + `AsLocalDateTime = true` (DTO attribute) + `asLocalDateTime: true` (Angular field config) together. Never mix types between layers.
:::

The mechanism relies on a timezone header (`X-Client-TimeZone`) automatically added to every HTTP request by the Angular interceptor, and read on the backend by `IClientTimeZoneContext`.

---

## `IClientTimeZoneContext`

`IClientTimeZoneContext` is a scoped service automatically registered and populated from the `X-Client-TimeZone` HTTP header on every request. It is used transparently by `BIA.Net.Core.Domain.SpecificationHelper` for filtering, but can also be injected in project services when timezone-aware business logic is needed.

:::note
The default implementation is `HttpClientTimeZoneContext`, registered in `BIA.Net.Core.Presentation.Api`. If you need custom logic to resolve the client timezone (e.g. from a user profile or a different header), you can implement `IClientTimeZoneContext` yourself and register it in your IoC configuration.
:::

| Property / Method | Type | Example value | Use |
|---|---|---|---|
| `IanaTimeZoneId` | `string` | `"Europe/Paris"` | IANA identifier read from the HTTP header; falls back to `"UTC"` if absent. Useful for logging or passing to third-party APIs. |
| `WindowsTimeZoneId` | `string` | `"Romance Standard Time"` | Windows timezone id derived from the IANA id. Required format for SQL Server `AT TIME ZONE` expressions in raw queries. |
| `WindowsTimeZone` | `TimeZoneInfo` | *(TimeZoneInfo for UTC+1/+2)* | Standard .NET timezone object. Use with `TimeZoneInfo.ConvertTimeFromUtc(utcDate, ctx.WindowsTimeZone)` in project code. |
| `Zone` | `DateTimeZone` (NodaTime) | *(NodaTime zone for Europe/Paris)* | Daylight Saving Times (DST) aware timezone object used internally by `BIA.Net.Core.Domain.SpecificationHelper` for filter arithmetic. Can be used directly with NodaTime in project code. |
| `GetClientNow()` | `DateTime` | `2024-01-15 14:30:00` *(local)* | Returns the current date and time expressed in the client's timezone. Used automatically for `today` / `beforeToday` / `afterToday` filter modes. Call it directly when you need "now" in the user's timezone. |

---

## Configuration

### Backend

#### Entity

Declare the field as `DateTimeOffset` instead of `DateTime` in your entity class.

```csharp title="MyEntity.cs"
/// <summary>
/// Gets or sets the scheduled start date and time (stored with UTC offset).
/// </summary>
public DateTimeOffset StartDateTime { get; set; }

/// <summary>
/// Gets or sets the scheduled end date and time (nullable, stored with UTC offset).
/// </summary>
public DateTimeOffset? EndDateTime { get; set; }
```

:::tip
After adding a `DateTimeOffset` property, create a database migration:
- SQL Server column type: `datetimeoffset`
- PostgreSQL column type: `timestamp with time zone`
:::

#### DTO (Form and/or List)

Use `DateTimeOffset` for the property type **and** add `Type = "datetime"` plus `AsLocalDateTime = true` to the `[BiaDtoField]` attribute.

```csharp title="MyEntityDto.cs"
/// <summary>
/// Gets or sets the scheduled start date and time.
/// </summary>
[BiaDtoField(Required = true, Type = "datetime", AsLocalDateTime = true)]
public DateTimeOffset StartDateTime { get; set; }

/// <summary>
/// Gets or sets the scheduled end date and time.
/// </summary>
[BiaDtoField(Required = false, Type = "datetime", AsLocalDateTime = true)]
public DateTimeOffset? EndDateTime { get; set; }
```

The same attribute must be applied identically in both the **form DTO** and the **list DTO** when you use [separate DTOs for list and form](60-ListDtoAndFormDto.md).

```csharp title="MyEntityListDto.cs"
[BiaDtoField(Required = true, Type = "datetime", AsLocalDateTime = true)]
public DateTimeOffset StartDateTime { get; set; }

[BiaDtoField(Required = false, Type = "datetime", AsLocalDateTime = true)]
public DateTimeOffset? EndDateTime { get; set; }
```

#### Mapper

Map the `DateTimeOffset` property as you would any other field — no extra code is needed for timezone handling.

```csharp title="MyEntityMapper.cs"
// ExpressionCollection — used for sort and filter
{ HeaderName.StartDateTime, entity => entity.StartDateTime },
{ HeaderName.EndDateTime,   entity => entity.EndDateTime   },

// DtoToEntity
entity.StartDateTime = dto.StartDateTime;
entity.EndDateTime   = dto.EndDateTime;

// EntityToDto
StartDateTime = entity.StartDateTime,
EndDateTime   = entity.EndDateTime,

// CSV export — use .UtcDateTime to export the stored UTC value
{ HeaderName.StartDateTime, () => CSVDateTime(dto.StartDateTime.UtcDateTime)  },
{ HeaderName.EndDateTime,   () => CSVDateTime(dto.EndDateTime?.UtcDateTime)   },
```

:::info
`BIA.Net.Core.Domain.SpecificationHelper` inspects the lambda expression registered in `ExpressionCollection`. When it detects that the mapped property is of type `DateTimeOffset` (or `DateTimeOffset?`), it automatically applies `IClientTimeZoneContext` to shift filter values to the correct timezone. No extra code is required in the mapper.
:::

---

### Frontend

#### TypeScript interface

The interface field stays typed as `Date` (or `Date | null`) — identical to a regular datetime field.

```typescript title="my-entity.ts"
export interface MyEntity extends BaseDto<number> {
  // ...
  startDateTime: Date;
  endDateTime: Date | null;
}
```

#### Field configuration (`BiaFieldConfig`)

Set `type: PropType.DateTime` and add `asLocalDateTime: true` to activate local time mode for the field.

```typescript title="my-entity.ts"
Object.assign(
  new BiaFieldConfig('startDateTime', 'myEntity.startDateTime'),
  {
    type: PropType.DateTime,
    isRequired: true,
    asLocalDateTime: true,   // ← activates local time mode
  }
),
Object.assign(
  new BiaFieldConfig('endDateTime', 'myEntity.endDateTime'),
  {
    type: PropType.DateTime,
    asLocalDateTime: true,   // ← activates local time mode
  }
),
```

Apply `asLocalDateTime: true` in **both** the form fields config and the list fields config when they are separate:

```typescript title="my-entity-list.ts"
Object.assign(
  new BiaFieldConfig('startDateTime', 'myEntity.startDateTime'),
  {
    type: PropType.DateTime,
    isRequired: true,
    asLocalDateTime: true,
  }
),
Object.assign(
  new BiaFieldConfig('endDateTime', 'myEntity.endDateTime'),
  {
    type: PropType.DateTime,
    asLocalDateTime: true,
  }
),
```

:::info
When `asLocalDateTime: true`, the framework automatically:
- Appends *(Local time)* to the column header in the table.
- Disables the free-text column search (replaced by a date-picker filter).
- Converts filter input values to UTC before sending them to the backend.
:::

#### DAS service

Pass the **form** `BiaFieldsConfig` to the `AbstractDas` constructor. This is the only configuration required on the Angular service side.

```typescript title="my-entity-das.service.ts"
@Injectable({ providedIn: 'root' })
export class MyEntityDas extends AbstractDas<MyEntityList, MyEntity> {
  constructor(injector: Injector) {
    super(injector, 'MyEntities', myEntityFieldsConfiguration);
    //                            ^^^^^^^^^^^^^^^^^^^^^^^^^^
    //   Pass the FORM fields config (not the list config).
  }
}
```

:::warning
Always pass the **form** fields configuration (not the list one) because PUT and POST use the form DTO. If you pass the list config or no config, local-time fields will be serialized as UTC-shifted dates and stored incorrectly.
:::

:::info
`AbstractDas` reads the fields config at construction time, extracts all fields where `asLocalDateTime === true`, and stores them as `localTimeFields`. On every `put()` / `post()` call, `DateHelperService.fillDateWithLocalTimeFields()` serializes those fields with `value.toISOString()` (true UTC conversion) while all other `Date` fields use `DateHelperService.toUtc()` (copies local digits as UTC).
:::

---

## What happens at runtime

### Sending a date to the backend (PUT / POST)

| Field type | Serialization | Example (browser in UTC+1) |
|---|---|---|
| Regular `Date` (`asLocalDateTime: false`) | `toUtc()` — local digits copied as UTC | User enters 14:30 → sent as `"2024-01-15T14:30:00.000Z"` |
| Local `Date` (`asLocalDateTime: true`) | `toISOString()` — true UTC conversion | User enters 14:30 → sent as `"2024-01-15T13:30:00.000Z"` |

The backend receives a UTC instant. EF Core stores it as `datetimeoffset` (SQL Server) or `timestamptz` (PostgreSQL), always with offset `+00:00`.

### Receiving a date from the backend (GET)

The backend serialises the `DateTimeOffset` as a UTC ISO string (e.g. `"2024-01-15T13:30:00+00:00"`). The Angular `Date` pipe and PrimeNG's calendar, operating in the browser's local timezone, render it as `14:30` automatically — no project-side conversion needed.

### Filtering

When the user sets a filter on a local date/time column:

**Frontend**

1. `BiaClientTimeZoneInterceptor` adds the `X-Client-TimeZone: ...` header to the HTTP request.

**Backend**

1. `HttpClientTimeZoneContext` reads the header and populates `IClientTimeZoneContext`.
2. `BIA.Net.Core.Domain.SpecificationHelper` inspects the mapper expression, detects `DateTimeOffset`, and uses `IClientTimeZoneContext.Zone` (NodaTime) to shift the filter boundary to the correct UTC instant.
3. For `today` / `beforeToday` / `afterToday` modes, `IClientTimeZoneContext.GetClientNow()` computes "today" in the client's timezone before building the date boundary.

:::info
Free-text search is disabled on `asLocalDateTime` columns because a raw string match on a UTC `DateTimeOffset` value would not produce meaningful results in local time.
:::

### Table column header

Columns with `asLocalDateTime: true` automatically display a suffix:

> **Scheduled start** *(Local time)*

This is handled by `BiaTableComponent.getColumnHeader()` which appends the `bia.localDateTime` translation key.

---