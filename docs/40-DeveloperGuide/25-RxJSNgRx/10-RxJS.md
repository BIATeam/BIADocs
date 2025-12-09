# RxJS in Angular

A complete guide for building reactive, scalable, maintainable applications with Angular, RxJS.

---

## 1. RxJS in Angular

Angular uses RxJS extensively for handling asynchronous operations, reactive forms, events, and global state.

### 1.1 What Are Observables?

Observables represent values over time.

```ts
myObservable$.subscribe(value => console.log(value));
```

Common Angular APIs that return Observables:

- HttpClient  
- FormControl.valueChanges  
- Router.events  
- NgRx Store  

---

### 1.2 Essential RxJS Operators

#### Creation Operators

| Operator | Description |
|---------|-------------|
| `of()` | Emits fixed values |
| `from()` | Converts promises or arrays |
| `interval()` | Emits values on intervals |

#### Transformation Operators

```ts
map(x => x * 2)
switchMap(v => api.search(v))
mergeMap(...)
concatMap(...)
exhaustMap(...)
```

| Operator | Best Use |
|----------|----------|
| switchMap | Cancel previous requests (autocomplete) |
| mergeMap | Parallel tasks |
| concatMap | Queue requests |
| exhaustMap | Ignore new triggers while busy |

#### Filtering Operators

```ts
filter(x => x > 10)
debounceTime(300)
distinctUntilChanged()
take(1)
takeUntil(this.destroy$)
```

---

### Example: Search Autocomplete

```ts
this.searchResults$ = this.searchControl.valueChanges.pipe(
  debounceTime(300),
  distinctUntilChanged(),
  switchMap(term => this.api.search(term))
);
```

---

## 2. Using RxJS in Angular Components

Prefer the `async` pipe.

Component:

```ts
readonly user$ = this.userService.getUser();
```

Template:

```html
<div *ngIf="user$ | async as user">
  Hello {{ user.name }}
</div>
```

For more informations on RxJS, visit the official documentation: https://rxjs.dev/guide/overview