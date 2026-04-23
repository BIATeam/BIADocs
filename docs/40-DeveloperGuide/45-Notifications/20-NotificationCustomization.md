---
sidebar_position: 1
---

# Customizing the Notification Feature

This guide explains how to extend the BIA notification feature in your application — adding custom fields, columns, and views — without modifying the `bia-ng` package.

## Overview

The notification feature is split into two layers:

- **`bia-ng` package** — base implementation (entity, store, services, components). Treat as read-only in a real project (it comes from node_modules).
- **Your application** — extends the base with project-specific fields and behavior.

The entry point is `BiaNotificationModule.forFeature(config)`, which lets you override any part of the feature declaratively.

---

## What you can customize

```ts
export interface BiaNotificationModuleConfig {
  // Override any routed view component
  indexComponent?: Type<unknown>;
  detailComponent?: Type<unknown>;
  editComponent?:   Type<unknown>;
  newComponent?:    Type<unknown>;
  itemComponent?:   Type<unknown>;
  // Override the CRUD config (columns, feature flags)
  crudConfiguration?: CrudConfig<NotificationListItem>;
  // Override DI providers (DAS, service, SignalR, options)
  providers?: Provider[];
}
```

---

## Step-by-step: adding a custom field

This example adds an `acknowledgedAt` timestamp field — a date set when the user explicitly acknowledges a notification.

### 1. DotNet — Entity

Add the property to the concrete `Notification` entity:

```csharp
// Domain/Notification/Entities/Notification.cs
public class Notification : BaseNotification
{
    /// <summary>Gets or sets the date the notification was acknowledged.</summary>
    public DateTimeOffset? AcknowledgedAt { get; set; }
}
```

### 2. DotNet — DTOs

Add the field to both DTOs. 

```csharp
// Domain.Dto/Notification/NotificationDto.cs
public class NotificationDto : BaseNotificationDto
{
    [BiaDtoField(AsLocalDateTime = true)]
    public DateTimeOffset? AcknowledgedAt { get; set; }
}

// Domain.Dto/Notification/NotificationListItemDto.cs
public class NotificationListItemDto : BaseNotificationListItemDto
{
    [BiaDtoField(AsLocalDateTime = true)]
    public DateTimeOffset? AcknowledgedAt { get; set; }
}
```

### 3. DotNet — List item mapper

Override three methods in `NotificationListItemMapper`:

- `ExpressionCollection` — enables sorting and filtering on the column
- `EntityToDto` — maps the entity field to the DTO
- `DtoToCellMapping` — enables CSV export

```csharp
// Domain/Notification/Mappers/NotificationListItemMapper.cs
public class NotificationListItemMapper(UserContext userContext) :
    BaseNotificationListItemMapper<NotificationListItemDto, Notification>(userContext)
{
    public override ExpressionCollection<Notification> ExpressionCollection
    {
        get => new ExpressionCollection<Notification>(base.ExpressionCollection)
        {
            { HeaderName.AcknowledgedAt, n => n.AcknowledgedAt },
        };
    }

    public override Expression<Func<Notification, NotificationListItemDto>> EntityToDto(string mapperMode)
    {
        return base.EntityToDto(mapperMode).CombineMapping(entity => new NotificationListItemDto
        {
            AcknowledgedAt = entity.AcknowledgedAt,
        });
    }

    public override Dictionary<string, Func<string>> DtoToCellMapping(NotificationListItemDto dto)
    {
        return new Dictionary<string, Func<string>>(base.DtoToCellMapping(dto))
        {
            { HeaderName.AcknowledgedAt, () => CSVDate(dto.AcknowledgedAt?.UtcDateTime) },
        };
    }

    public new struct HeaderName
    {
        public const string AcknowledgedAt = "acknowledgedAt";
    }
}
```

### 4. DotNet — Full notification mapper

Override `EntityToDto` and `DtoToEntity` in `NotificationMapper` for the create/edit form:

```csharp
// Domain/Notification/Mappers/NotificationMapper.cs
public class NotificationMapper(UserContext userContext) :
    BaseNotificationMapper<NotificationDto, Notification>(userContext)
{
    public override Expression<Func<Notification, NotificationDto>> EntityToDto(string mapperMode)
    {
        return base.EntityToDto(mapperMode).CombineMapping(entity => new NotificationDto
        {
            AcknowledgedAt = entity.AcknowledgedAt,
        });
    }

    public override void DtoToEntity(NotificationDto dto, ref Notification entity)
    {
        base.DtoToEntity(dto, ref entity);
        entity.AcknowledgedAt = dto.AcknowledgedAt;
    }
}
```

### 5. DotNet — Model builder

Configure the column in `NotificationModelBuilder`:

```csharp
// Infrastructure.Data/ModelBuilders/NotificationModelBuilder.cs
protected override void CreateNotificationModel(ModelBuilder modelBuilder)
{
    base.CreateNotificationModel(modelBuilder);

    modelBuilder.Entity<Notification>()
        .Property(n => n.AcknowledgedAt)
        .IsRequired(false);
}
```

### 6. DotNet — Migration

Add an EF Core migration by using a standard Add-Migration command.

---

### 7. Angular — Extended models

Extend both the detail model and the list item model:

```ts
// features/notifications/model/specific-notification.ts
import { Notification } from 'bia-ng/features/public-api';

export interface SpecificNotification extends Notification {
  acknowledgedAt?: Date;
}
```

```ts
// features/notifications/model/specific-notification-list-item.ts
import {
  NotificationListItem,
  notificationFieldsConfiguration,
} from 'bia-ng/features/public-api';
import { PropType } from 'bia-ng/models/enum/public-api';
import { BiaFieldConfig, BiaFieldsConfig } from 'bia-ng/models/public-api';

export interface SpecificNotificationListItem extends NotificationListItem {
  acknowledgedAt?: Date;
}

export const specificNotificationFieldsConfiguration: BiaFieldsConfig<SpecificNotificationListItem> = {
  columns: [
    ...notificationFieldsConfiguration.columns,
    Object.assign(
      new BiaFieldConfig<SpecificNotificationListItem>('acknowledgedAt', 'notification.acknowledgedAt'),
      { type: PropType.DateTime, asLocalDateTime: true }
    ),
  ],
};
```

### 8. Angular — CRUD configuration

Create a local `CrudConfig` that references your extended fields. The `storeKey` **must** stay `'notifications'` — it must match the base store's key since NgRx action type strings are global.

```ts
// features/notifications/specific-notification.constants.ts
import { CrudConfig } from 'bia-ng/shared/public-api';
import { SpecificNotificationListItem, specificNotificationFieldsConfiguration } from './model/specific-notification-list-item';

export const specificNotificationCRUDConfiguration: CrudConfig<SpecificNotificationListItem> =
  new CrudConfig({
    featureName: 'notifications',
    storeKey: 'notifications',       // must match the base store key
    fieldsConfig: specificNotificationFieldsConfiguration,
    useCalcMode: false,
    useSignalR: true,
    useView: true,
    usePopup: true,
    useOfflineMode: false,
    useCompactMode: false,
    useVirtualScroll: false,
    useRefreshAtLanguageChange: true,
  });
```

### 9. Angular — DAS service

Extend `AbstractDas` directly (not `NotificationDas`) so you can pass your specific fields config to the constructor. This ensures the framework correctly handles `asLocalDateTime` conversions for your new field.

```ts
// features/notifications/services/specific-notification-das.service.ts
import { Injectable, Injector } from '@angular/core';
import { AbstractDas } from 'bia-ng/core/public-api';
import { Observable } from 'rxjs';
import { SpecificNotification } from '../model/specific-notification';
import { specificNotificationFieldsConfiguration } from '../model/specific-notification-list-item';

@Injectable()
export class SpecificNotificationDas extends AbstractDas<SpecificNotification> {
  constructor(injector: Injector) {
    super(injector, 'Notifications', specificNotificationFieldsConfiguration);
  }

  setUnread(id: number): Observable<SpecificNotification> {
    return this.get({ endpoint: 'setUnread', id });
  }
}
```

### 10. Angular — Service

Extend `NotificationService` and override only `crudConfiguration`. The store selectors, actions, and effects are all reused from the base.

```ts
// features/notifications/services/specific-notification.service.ts
import { Injectable, Injector } from '@angular/core';
import { Store } from '@ngrx/store';
import { AuthService } from 'bia-ng/core/public-api';
import {
  NotificationDas,
  NotificationOptionsService,
  NotificationService,
  NotificationsSignalRService,
} from 'bia-ng/features/public-api';
import { BiaAppState } from 'bia-ng/store/public-api';
import { specificNotificationCRUDConfiguration } from '../specific-notification.constants';

@Injectable()
export class SpecificNotificationService extends NotificationService {
  public override crudConfiguration = specificNotificationCRUDConfiguration;

  constructor(
    protected override store: Store<BiaAppState>,
    public override dasService: NotificationDas,       // injected via token → resolves to SpecificNotificationDas
    public override signalRService: NotificationsSignalRService,
    public override optionsService: NotificationOptionsService,
    protected override injector: Injector,
    protected override authService: AuthService
  ) {
    super(store, dasService, signalRService, optionsService, injector, authService);
  }
}
```

> **Note:** `dasService` is typed as `NotificationDas` (the token), not `SpecificNotificationDas`. Angular resolves it to `SpecificNotificationDas` via the `{ provide: NotificationDas, useClass: SpecificNotificationDas }` provider in the module.

### 11. Angular — Module

Wire everything together with `BiaNotificationModule.forFeature()`:

```ts
// features/notifications/specific-notification.module.ts
import { NgModule } from '@angular/core';
import {
  BiaNotificationModule,
  NotificationDas,
  NotificationService,
} from 'bia-ng/features/public-api';
import { CrudItemService } from 'bia-ng/shared/public-api';
import { SpecificNotificationDas } from './services/specific-notification-das.service';
import { SpecificNotificationService } from './services/specific-notification.service';
import { specificNotificationCRUDConfiguration } from './specific-notification.constants';

@NgModule({
  imports: [
    BiaNotificationModule.forFeature({
      crudConfiguration: specificNotificationCRUDConfiguration,
      providers: [
        { provide: NotificationDas, useClass: SpecificNotificationDas },
        { provide: NotificationService, useClass: SpecificNotificationService },
        { provide: CrudItemService, useExisting: NotificationService },
      ],
    }),
  ],
})
export class SpecificNotificationModule {}
```

Register it in your app routing instead of the default `BiaNotificationModule`:

```ts
// app-routing.module.ts
{
  path: 'notifications',
  loadChildren: () =>
    import('./features/notifications/specific-notification.module')
      .then(m => m.SpecificNotificationModule),
}
```

### 12. Angular — i18n

Add the translation key in each language file under `src/assets/i18n/app/`:

```json
// en.json
{
  "notification": {
    "acknowledgedAt": "Acknowledged at"
  }
}

// fr.json
{
  "notification": {
    "acknowledgedAt": "Accusé de réception"
  }
}

// es.json
{
  "notification": {
    "acknowledgedAt": "Reconocido el"
  }
}
```

---

## Customizing a view component

To customize a view (e.g. the detail page), extend the base component and pass it via `detailComponent` in `forFeature()`.

### Example: adding an "Acknowledge" button to the detail view

```ts
// features/notifications/views/notification-detail/specific-notification-detail.component.ts
import { AsyncPipe, DatePipe } from '@angular/common';
import { Component } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Store } from '@ngrx/store';
import { TranslateModule } from '@ngx-translate/core';
import { AuthService, BiaFileDownloaderService } from 'bia-ng/core/public-api';
import { NotificationDetailComponent } from 'bia-ng/features/notifications/views/notification-detail/notification-detail.component';
import { NotificationTeamWarningComponent, SpinnerComponent } from 'bia-ng/shared/public-api';
import { BiaAppState } from 'bia-ng/store/public-api';
import { ButtonDirective } from 'primeng/button';
import { Observable } from 'rxjs';
import { SpecificNotification } from '../../model/specific-notification';
import { SpecificNotificationService } from '../../services/specific-notification.service';

@Component({
  selector: 'app-specific-notification-detail',
  templateUrl: './specific-notification-detail.component.html',
  imports: [ButtonDirective, NotificationTeamWarningComponent, AsyncPipe, DatePipe, TranslateModule, SpinnerComponent],
})
export class SpecificNotificationDetailComponent extends NotificationDetailComponent {
  constructor(
    protected override store: Store<BiaAppState>,
    protected override router: Router,
    protected override activatedRoute: ActivatedRoute,
    protected override authService: AuthService,
    public override notificationService: SpecificNotificationService,
    protected override fileDownloaderService: BiaFileDownloaderService
  ) {
    super(store, router, activatedRoute, authService, notificationService, fileDownloaderService);
  }

  get specificNotification$(): Observable<SpecificNotification | undefined> {
    return this.notification$ as Observable<SpecificNotification | undefined>;
  }

  onAcknowledge(notification: SpecificNotification) {
    this.onSubmitted({ ...notification, acknowledgedAt: new Date() } as SpecificNotification);
  }
}
```

Template (`specific-notification-detail.component.html`) — add the field display and the button:

```html
@if (specificNotification$ | async; as notification) {
  @if (notification && notification.id) {
    <div class="flex flex-column flex-wrap justify-content-evenly">
      <!-- ... base fields ... -->
      <div>
        <b>{{ 'notification.acknowledgedAt' | translate }}</b><br />
        @if (notification.acknowledgedAt) {
          {{ notification.acknowledgedAt | date: 'short' }}
        } @else { - }
      </div>
    </div>
  }
  <div class="flex flex-row justify-content-between align-items-center">
    <!-- ... base buttons ... -->
    @if (!notification.acknowledgedAt) {
      <button pButton icon="pi pi-check-circle"
        label="{{ 'notification.acknowledgedAt' | translate }}"
        class="p-button-outlined"
        (click)="onAcknowledge(notification)">
      </button>
    }
  </div>
}
```

Register it in the module:

```ts
BiaNotificationModule.forFeature({
  crudConfiguration: specificNotificationCRUDConfiguration,
  detailComponent: SpecificNotificationDetailComponent,
  providers: [ ... ],
})
```

## Key rules

- **`storeKey` must be `'notifications'`** — NgRx action type strings are global identifiers. The specific config must share the same store key as the base.
- **Extend `AbstractDas` directly, not `NotificationDas`** — `NotificationDas` hardcodes the base fields config in its constructor. You need to pass your own.
- **`dasService` is injected by token** — type it as `NotificationDas` in the service constructor; Angular resolves it to `SpecificNotificationDas` via the provider alias.
- **`bia-features/notifications/notification.module.ts` stays untouched** — it remains a one-liner wrapping `BiaNotificationModule`. Your customization lives in a separate module.
