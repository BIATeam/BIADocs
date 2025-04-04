---
sidebar_position: 1
---

# Data Service
This document explains how to quickly create a Service that get or update data from database.

## BIA accelerator
Some classes have been incorporate to accelerate the creation of a service:
    - AppServiceBase
    - FilteredServiceBase (inherit of AppServiceBase)
    - CrudAppServiceBase (inherit of FilteredServiceBase)
    - CrudAppServiceListAndItemBase (inherit of FilteredServiceBase)

It is recommended to always create service that inherit of FilteredServiceBase to be able to correctly filter the access to the data.

### FilteredServiceBase
It add a filter that can be based on the user context or functional need.
Example are explain in [FilterData](../15-RightManagement/40-FilterData.md).

With an implemented dtos and mapper between dto and entity, this class offer add, read, update and delete function secured by the filter.

### CrudAppServiceBase
This class is use a dto and a mapper passed in the declaration. And simplify the usage of the functions.

### CrudAppServiceListAndItemBase
This class is use 2 dtos and 2 mapper passed in the declaration. And simplify the usage of the functions.
A dto is use to add, read, update and delete a simple item.
The second for of list items.

It can be use in CRUD when detail screen request more complex info than list. To increase performances of the list.

## Transaction
If a service preform several update add or delete actions, it should encapsulate in a transaction.
It avoid to stay in a partial state if the first action run correctly but not the others.

```csharp
    public override async Task<PlaneDto> AddAsync(PlaneDto dto, string mapperMode = null)
    {
        using (var transaction = new TransactionScope(TransactionScopeAsyncFlowOption.Enabled))
        {
            // begin of the actions in database
            var dtoAdded = await base.AddAsync(dto, mapperMode);
            dtoAdded.Msn = "Plane number " + dtoAdded.Id;
            var dtoUpdated = await base.UpdateAsync(dtoAdded, mapperMode);
            // end of the actions in database

            // commit the add in database only if the to update haven't fail.
            transaction.Complete();

            return dtoUpdated;
        }
    }
```