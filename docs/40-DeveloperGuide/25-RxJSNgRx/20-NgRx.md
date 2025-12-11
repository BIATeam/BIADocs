# NgRx with the BIA Framework

This concise tutorial explains how we use NgRx with the BIA Framework, following the project's service-façade pattern: components talk to a feature `Service` (which extends `CrudItemService<T>`), and that service dispatches actions and exposes selectors as observables.
You first need to have a general idea of how NgRx works and can use the official site for a basic explanation: https://ngrx.io/guide/store

**Key files (per feature)**

- `feature.constants.ts` — store key and flags.
- `feature.model.ts` — data model.
- `feature-das.service.ts` — Data Access Service: raw HTTP calls.
- `feature.service.ts` — Feature service (extends `CrudItemService<T>`). Dispatches actions and exposes selectors.
- `store/feature-actions.ts` — action creators.
- `store/feature-reducer.ts` — entity adapter + reducer.
- `store/feature.state.ts` — selectors.
- `store/feature-effects.ts` — side effects calling DAS.

## Store Model Structure: CrudState + EntityState

Every feature store extends two NgRx/BIA base interfaces:

**CrudState** (from BIA):
```ts
export interface CrudState<T> {
  currentItem: T;                    // currently selected item (for edit/detail view)
  currentItemId: any;                // ID of current item
  totalCount: number;                // total count of all items (for pagination)
  lastLazyLoadEvent: TableLazyLoadEvent; // last table pagination/filter event
  loadingGetAll: boolean;            // loading state for list operations
  loadingGet: boolean;               // loading state for single item load
}
```

**EntityState** (from NgRx/entity):
```ts
export interface EntityState<T> {
  ids: string[] | number[];          // array of entity IDs (auto-managed by adapter)
  entities: { [id: string | number]: T }; // normalized entity map (auto-managed by adapter)
}
```

**Combined in your feature state:**
```ts
// from my-features-reducer.ts
export interface State extends CrudState<MyFeature>, EntityState<MyFeature> {
  // optional: add any custom feature-specific properties here
  currentItemHistorical: HistoricalEntryDto[];
}

export const INIT_STATE: State = myFeaturesAdapter.getInitialState({
  ...DEFAULT_CRUD_STATE(),        // initializes CrudState fields
  currentItemHistorical: [],       // your custom properties
});
```

**Why this pattern:**
- **CrudState**: standard CRUD UI state (current item, pagination, loading flags). Shared across features for consistency.
- **EntityState**: normalized entity storage and cached selector functions (getters for list, by ID, etc.) via the `entityAdapter`.
- **Entity adapter**: automatically manages `ids` and `entities` and provides memoized selector generators.

**In the reducer:**
- Use `adapter.setAll(items, state)` to populate the list.
- Use `adapter.updateOne/upsertOne/removeOne` to modify entities.
- Manually set `CrudState` fields (currentItem, totalCount, loading flags).

Example from `my-features-reducer.ts`:
```ts
on(FeatureMyFeaturesActions.loadAllByPostSuccess, (state, { result, event }) => {
  const stateUpdated = myFeaturesAdapter.setAll(result.data, state);  // sets ids[] and entities{}
  stateUpdated.totalCount = result.totalCount;                   // CrudState field
  stateUpdated.lastLazyLoadEvent = event;                        // CrudState field
  stateUpdated.loadingGetAll = false;                            // CrudState field
  return stateUpdated;
}),
```

**In selectors** (state.ts):
```ts
export const getAllMyFeatures = adapter.getSelectors().selectAll;     // get all entities via adapter
export const getMyFeaturesTotalCount = (state: State) => state.totalCount; // get CrudState field
export const getCurrentMyFeature = (state: State) => state.currentItem; // get CrudState field
```

---

**1) Where to call actions (in `CrudItemService`)**

Pattern: components do NOT dispatch NgRx actions directly. Instead they call methods on the feature service which internally dispatch actions. Example (from `MyFeatureService`):

```ts
public create(crudItem: MyFeature) {
  crudItem.siteId = this.getParentIds()[0];
  this.store.dispatch(FeatureMyFeaturesActions.create({ myFeature: crudItem }));
}

public loadAllByPost(event: TableLazyLoadEvent) {
  this.store.dispatch(FeatureMyFeaturesActions.loadAllByPost({ event }));
}
```

Why: keeps components small and reusable; the service can add context (parent IDs, auth info) before dispatching.

Recommendation:

- Put all action dispatches in the feature service methods (`load`, `loadAllByPost`, `create`, `update`, `remove`, etc.).
- Use the service to enrich payloads (parent keys, defaults) before dispatch.

**2) How to expose store data from selectors (from the service)**

The service should expose observables built from `Store.select(...)` using feature selectors. Example:

```ts
public crudItems$: Observable<MyFeature[]> = this.store.select(
  FeatureMyFeaturesStore.getAllMyFeatures
);
public totalCount$: Observable<number> = this.store.select(
  FeatureMyFeaturesStore.getMyFeaturesTotalCount
);
public loadingGetAll$: Observable<boolean> = this.store.select(
  FeatureMyFeaturesStore.getMyFeatureLoadingGetAll
);
```

Components subscribe (async pipe) to these observables:

```html
<p-table [value]="crudItemService.crudItems$ | async"> ... </p-table>
<span *ngIf="(crudItemService.loadingGetAll$ | async)">Loading...</span>
```

**3) Adding a custom action that calls a custom API function**

Example scenario: add a custom API `publish` that marks an item published on server.

Steps:

1. Add action creators (`store/feature-actions.ts`):

```ts
export const publish = createAction(
  '[MyFeature] Publish',
  props<{ id: number }>()
);
export const publishSuccess = createAction(
  '[MyFeature] Publish Success',
  props<{ id: number; result: any }>()
);
export const publishFailure = createAction(
  '[MyFeature] Publish Failure',
  props<{ error: any }>()
);
```

2. Add DAS method (`feature-das.service.ts`):

```ts
public publish(id: number): Observable<any> {
  return this.http.post(`/api/my-feature/${id}/publish`, {});
}
```

3. Add an Effect (`store/feature-effects.ts`):

```ts
publish$ = createEffect(() =>
  this.actions$.pipe(
    ofType(MyFeatureActions.publish),
    concatMap(action =>
      this.das.publish(action.id).pipe(
        map(result =>
          MyFeatureActions.publishSuccess({ id: action.id, result })
        ),
        catchError(error => of(MyFeatureActions.publishFailure({ error })))
      )
    )
  )
);
```

Notes:

- Use `concatMap` or `exhaustMap` depending on desired concurrency.
- Catch errors and dispatch a `failure` action so UI can react.

4. Handle success in reducer (`store/feature-reducer.ts`):

- If the publish modifies the entity state (e.g., `isPublished`), update the entity in the adapter with the returned result or by applying an update.

```ts
on(MyFeatureActions.publishSuccess, (state, { id, result }) =>
  adapter.updateOne({ id, changes: { isPublished: true, ... } }, state)
),
```

5. Add a convenience method on the feature service (`feature.service.ts`):

```ts
public publish(id: number) {
  this.store.dispatch(MyFeatureActions.publish({ id }));
}
```

6. Optional: service returns a Promise/Observable that resolves when the action completes.

Sometimes you want to call `publish` and await the server response. You can listen to the actions stream from the service. Inject `Actions` into your service (use the injector if the base `CrudItemService` provides it), then filter for success/failure:

```ts
import { Actions, ofType } from '@ngrx/effects';
import { first, filter, map } from 'rxjs/operators';

constructor(private actions$: Actions, /* other deps */) { }

public publishAndWait(id: number): Observable<any> {
  this.store.dispatch(MyFeatureActions.publish({ id }));
  return this.actions$.pipe(
    ofType(MyFeatureActions.publishSuccess, MyFeatureActions.publishFailure),
    filter(action => (action as any).id === id),
    first()
  );
}
```

Caveats:

- Make sure the success/failure actions carry an identifier to correlate responses.
- Injecting `Actions` in services is allowed but prefer to keep service responsibilities clear; usually the store + selectors are enough for most flows.

**4) Component usage pattern**

- For lists: call `crudItemService.loadAllByPost(event)` (or `crudItemService.loadAll()`), templates use `crudItemService.crudItems$ | async` and `crudItemService.loadingGetAll$ | async`.
- For detail/edit: the component calls `crudItemService.load(id)`, binds to `crudItemService.crudItem$ | async`, and calls `crudItemService.save/create/update/remove` for operations.

Example (component):

```ts
ngOnInit() {
  const id = +this.route.snapshot.paramMap.get('id');
  if (id) {
    this.crudItemService.load(id);
  }
}

onSave(item: MyFeature) {
  if (item.id) {
    this.crudItemService.update(item);
  } else {
    this.crudItemService.create(item);
  }
}
```

**5) Naming and conventions**

- Action names: `[FeatureName] actionDescription`.
- Files: group store files in `store/` (actions, reducer, state, effects).
- Use a `feature.constants.ts` with `storeKey` and `featureName` to keep names consistent.
- Keep DAS as thin HTTP wrappers; effects map DAS results to actions.

**6) Best practices and pitfalls**

- Prefer service dispatch over component dispatch: adds contextual logic and simplifies components.
- Keep effects pure: do side-effects in DAS and map results in effects.
- Avoid long-lived subscriptions in services without unsubscribing; prefer components to use `async` pipe.
- For single-request responses, correlate success actions with an `id` so callers can filter the `Actions` stream.
