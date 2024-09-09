---
sidebar_position: 1
---

# Offline mode
This file explains how to use the feature offline in your V3 project.

## Prerequisite
This feature must be associated with the installation of the service worker angular ([ng add @angular/pwa](https://www.npmjs.com/package/@angular/pwa))

<!-- ### Knowledge to have: -->

## Overview
The purpose of this feature is to keep http requests in memory when the server is unavailable. When the server is available again, the requests are executed.
This feature also makes it possible to store data on GET http request.

## Activation
In the **\src\app\core\core.module.ts** file

Add this:

```ts
import { BiaOnlineOfflineService } from './bia-core/services/bia-online-offline.service';
import { biaOnlineOfflineInterceptor } from './bia-core/interceptors/bia-online-offline.interceptor';
import { AppDB } from './bia-core/db';
const ONLINEOFFLINE = [BiaOnlineOfflineService, biaOnlineOfflineInterceptor, AppDB];
```

and add the **ONLINEOFFLINE** array in the **NgModule**, **providers** :

```ts
@NgModule({
  providers: [
    ...ONLINEOFFLINE,
  ]
})
```

## Usage

This offline mode is not activated for all requests. It is the developer who must specify it with the **offlineMode** parameter in effect class.

### POST PUT DELETE

if you want to activate this mode for an http request, add the following constant in your constants feature file :

```ts
export const useOfflineMode = true;
```

Finally, modified the call in the effect by adding this parameter (here an example on a create)

```ts
return this.planeDas.post({ item: plane, offlineMode: useOfflineMode }).pipe(...
```

### GET

If you want to keep in memory the data of a domain for example, you just have to modify the effect like this:

```ts
this.planeTypeDas.getList({ endpoint: 'allOptions', offlineMode: BiaOnlineOfflineService.isModeEnabled }).pipe(...
```

### BiaOnlineOfflineService

The **BiaOnlineOfflineService** (\src\app\core\bia-core\services\bia-online-offline.service.ts) service offers two properties:

* isModeEnabled : Allows you to know if the offline feature has been activated or not (see the chapter above, Activation)
* serverAvailable$: is an observable returning true if the server is available
* syncCompleted$: is an observable returning true if synchronization is completed.

Here an example of use

```ts
// if the offline feature is enabled
if (BiaOnlineOfflineService.isModeEnabled) {
  this.sub.add(
    // I subscribe to the observable serverAvailable$
    this.injector.get<BiaOnlineOfflineService>(BiaOnlineOfflineService).syncCompleted$.pipe(skip(1), filter(x => x === true)).subscribe(() => {
      // If the server becomes available again, I refresh my table.
      this.onLoadLazy(this.planeListComponent.getLazyLoadMetadata());
    })
  );
}
```
