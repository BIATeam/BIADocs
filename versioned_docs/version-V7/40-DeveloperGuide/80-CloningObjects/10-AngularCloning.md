---
sidebar_position: 1
---

# Cloning objects in Angular
## Why cloning ?
When an object cannot or must not be altered you can make a perfect copy of it to alter it as you wish, losing all the references to original object.
For example, when getting an object from the NgRx store, the object is readonly and cannot be modified during runtime. You need to clone the object if you want to alter it directly.
You can achieve that by using the **clone** global function.

## Example
```typescript
// Not allowed with NgRx immutability constraint :
forDisplayWithRuntimeError(teamTypeId: number) {
    return this.store.select(getAllTeamsOfType(teamTypeId)).pipe(
        tap(teams => teams.forEach(team => team.title = `${team.title} for display`)));
}

// Allowed with NgRx immutability constraint :
forDisplayWithNoError(teamTypeId: number) {
    return this.store.select(getAllTeamsOfType(teamTypeId)).pipe(
        map(teams => clone(teams)), 
        tap(teams => teams.forEach(team => team.title = `${team.title} for display`)));
}
```