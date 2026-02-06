---
sidebar_position: 90
---

# Offline mode
This file explains how to use the feature offline in your V3 project.

## Overview
The purpose of this feature is to keep http requests in memory when the server is unavailable. When the server is available again, the requests are executed.
This feature also makes it possible to store data on GET http request.

## Activation
In the **all-environments.ts** file

Set **enableOfflineMode** parameter to true:

```ts
enableOfflineMode: true,
```

## Local Debug

You cannot debug the Angular service worker using the classic debug mode (ng serve or VS Code debugger). To debug the service worker, you need to build your project in production mode and serve the compiled files with a static server.

The first step is to copy the content of the following files into the corresponding files:

* index.html → index.prod.html
* environment.ts → environment.prod.ts 


Then launch the following commands (Replace **ProjectName** with your actual project folder name):

```
ng build --configuration production
npx http-server .\dist\ProjectName -p 4200
```

Then, open your browser at http://localhost:4200 to debug the service worker.

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
