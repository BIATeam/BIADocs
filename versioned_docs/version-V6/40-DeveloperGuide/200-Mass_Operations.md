---
sidebar_position: 200
---

# Mass Operations (Bulk)

## Overview

The `TGenericRepositoryEF<TEntity, TKey>` class provides several high-performance methods for handling large-scale database operations. These methods are designed to efficiently handle bulk operations while maintaining performance and memory management through batching strategies.

This guide covers six essential mass operation methods:
- `ExecuteDeleteAsync` 
- `ExecuteUpdateAsync`
- `DeleteByIdsAsync`
- `MassAddAsync`
- `MassUpdateAsync`
- `MassDeleteAsync`

## Why Use Mass Operations?

Traditional Entity Framework operations (like `Add`, `Update`, `Remove`) work well for single entities or small collections, but they become inefficient when dealing with thousands or millions of records because:

1. **Performance Issues**: Each entity operation generates a separate SQL command
2. **Memory Consumption**: Large collections can cause memory pressure
3. **Transaction Overhead**: Multiple round-trips to the database
4. **Timeout Issues**: Long-running operations may exceed connection timeouts

Mass operations solve these problems by:
- **Batching**: Processing data in manageable chunks
- **Bulk Operations**: Using database-specific bulk insert/update/delete commands
- **Reduced Round-trips**: Minimizing database communication
- **Memory Management**: Processing data incrementally

## Benefits of the batchSize Parameter

 All the methods described below use the batchSize parameter. The batchSize parameter is a crucial optimization feature in mass database operations that offers several important benefits:

### Timeout Prevention
Strongly recommended for avoiding timeouts: One of the primary benefits of using batchSize is preventing database timeouts during large-scale operations. When processing thousands or millions of records without batching, the database operation can exceed the default command timeout limits, causing the entire operation to fail. By breaking large operations into smaller, manageable chunks, each batch completes within acceptable time limits.

### Reduced Table Locking Duration
Minimizing table locks: Database operations often require exclusive locks on tables or rows being modified. Without batching, a single operation affecting many records can hold these locks for extended periods, blocking other database operations and potentially causing performance bottlenecks. The recommended batch size of 100 records strikes an optimal balance between:
•	Processing efficiency (not too many small transactions)
•	Lock duration minimization (preventing long-running locks that block other operations)

## 1. ExecuteDeleteAsync

### Purpose
Deletes entities based on filter criteria without loading them into memory first.

### Method Signature
```csharp
Task<int> ExecuteDeleteAsync(Expression<Func<TEntity, bool>> filter = default, int? batchSize = 100)
```

### Parameters
- **filter**: Lambda expression to filter which entities to delete
- **batchSize**: Number of entities to process per batch (default: 100, null = no batching)

### Returns
Number of entities successfully deleted

### How It Works
1. Applies the filter to create a query
2. For batched operations: repeatedly takes batches and deletes them until no more entities match
3. For non-batched operations: deletes all matching entities in one operation
4. Uses SQL `DELETE` statements directly (no entity loading)

### Example with Planes
```csharp
// Delete all planes from a specific site that are inactive
int deletedCount = await this.Repository.ExecuteDeleteAsync(
    filter: p => p.SiteId == 5 && !p.IsActive,
    batchSize: 50
);

// Delete all planes older than 30 years (no batching)
var cutoffDate = DateTime.Now.AddYears(-30);
int oldPlanesDeleted = await this.Repository.ExecuteDeleteAsync(
    filter: p => p.FirstFlightDate < cutoffDate,
    batchSize: null
);

// Delete planes scheduled for maintenance before a certain date
int maintenanceDeleted = await this.Repository.ExecuteDeleteAsync(
    filter: p => p.NextMaintenanceDate < DateTime.Now.AddDays(-365)
);
```

### When to Use
- Conditional bulk deletions
- Data cleanup based on business rules  
- Removing entities matching complex criteria
- Scheduled data purging operations

---

## 2. ExecuteUpdateAsync

### Purpose
Updates multiple entities' fields based on filter criteria without loading them into memory.

### Method Signature
```csharp
Task<int> ExecuteUpdateAsync(IDictionary<string, object> fieldUpdates, Expression<Func<TEntity, bool>> filter = default, int? batchSize = 100)
```

### Parameters
- **fieldUpdates**: Dictionary mapping property names to new values
- **filter**: Lambda expression to filter which entities to update
- **batchSize**: Number of entities to process per batch (default: 100)

### Returns
Number of entities successfully updated

### How It Works
1. Validates that fieldUpdates contains at least one field
2. Builds SetProperty expressions from the dictionary
3. For large datasets: processes in batches by retrieving IDs first
4. Uses Entity Framework's `ExecuteUpdateAsync` with SQL `UPDATE` statements

### Example with Planes
```csharp
// Update maintenance status for planes at a specific site
var updates = new Dictionary<string, object>
{
    [nameof(Plane.IsMaintenance)] = true,
    [nameof(Plane.NextMaintenanceDate)] = DateTime.Now.AddMonths(6)
};

int updatedCount = await this.Repository.ExecuteUpdateAsync(
    fieldUpdates: updates,
    filter: p => p.SiteId == 3 && p.IsActive,
    batchSize: 25
);

// Mark all Boeing planes as inactive and set estimated price
var boeingUpdates = new Dictionary<string, object>
{
    [nameof(Plane.IsActive)] = false,
    [nameof(Plane.EstimatedPrice)] = 0m,
    [nameof(Plane.LastFlightDate)] = DateTime.Now
};

int boeingCount = await this.Repository.ExecuteUpdateAsync(
    fieldUpdates: boeingUpdates,
    filter: p => p.Manufacturer.Contains("Boeing")
);

// Update fuel levels for planes at specific airports
var fuelUpdates = new Dictionary<string, object>
{
    [nameof(Plane.FuelLevel)] = 0.8f * 1000, // 80% of 1000L capacity
    [nameof(Plane.IsMaintenance)] = false
};

int refueledCount = await this.Repository.ExecuteUpdateAsync(
    fieldUpdates: fuelUpdates,
    filter: p => p.CurrentAirportId == 1 && p.FuelLevel < 200
);

// Advanced example: Update multiple fields based on complex business logic
var businessRuleUpdates = new Dictionary<string, object>
{
    [nameof(Plane.IsActive)] = false,
    [nameof(Plane.IsMaintenance)] = true,
    [nameof(Plane.NextMaintenanceDate)] = DateTime.Now.AddDays(7),
    [nameof(Plane.EstimatedPrice)] = null, // Clear estimated price
    [nameof(Plane.TotalFlightHours)] = 0.0 // Reset flight hours
};

int businessRuleCount = await this.Repository.ExecuteUpdateAsync(
    fieldUpdates: businessRuleUpdates,
    filter: p => p.FirstFlightDate < DateTime.Now.AddYears(-25) && p.TotalFlightHours > 50000
);
```

### When to Use
- Bulk status updates
- Price adjustments across multiple entities
- Maintenance scheduling updates
- Data migration and transformation

---

## 3. DeleteByIdsAsync

### Purpose
Deletes multiple entities by their identifiers in an efficient, batched manner.

### Method Signature
```csharp
Task<int> DeleteByIdsAsync(IEnumerable<TKey> ids, int? batchSize = 100)
```

### Parameters
- **ids**: Collection of entity identifiers to delete
- **batchSize**: Number of entities to process per batch (default: 100, null = no batching)

### Returns
Number of entities successfully deleted

### How It Works
1. Validates input parameters
2. Groups IDs into batches of specified size
3. Uses Entity Framework's `ExecuteDeleteAsync` for each batch
4. Returns total count of deleted entities

### Example with Planes
```csharp
// Delete multiple planes by their IDs
var planeIdsToDelete = new List<int> { 1, 2, 3, 4, 5, 15, 28, 31 };

// Delete in batches of 3
int deletedCount = await this.Repository.DeleteByIdsAsync(planeIdsToDelete, batchSize: 3);
Console.WriteLine($"Deleted {deletedCount} planes");

// Delete all at once (no batching)
int deletedCount2 = await this.Repository.DeleteByIdsAsync(planeIdsToDelete, batchSize: null);
```

### When to Use
- Bulk deletion based on a list of known IDs

## 4. MassAddAsync

### Purpose
Adds a large number of entities efficiently using batching or bulk operations.

### Method Signature
```csharp
Task<int> MassAddAsync(IEnumerable<TEntity> items, int batchSize = 100, bool useBulk = false)
```

### Parameters
- **items**: Collection of entities to add
- **batchSize**: Number of entities to process per batch (default: 100)
- **useBulk**: Whether to use database bulk insert if supported (default: false)

### Returns
Number of entities successfully added

### How It Works
1. If bulk operations are supported and enabled, uses database-specific bulk insert
2. Otherwise, processes entities in batches using standard EF `AddRange`
3. Commits each batch separately to manage memory and transaction size
4. Resets the context between batches to prevent memory bloat

### Example with Planes
```csharp
// Add a large fleet of new planes
var newPlanes = new List<Plane>();
for (int i = 1; i <= 1000; i++)
{
    newPlanes.Add(new Plane
    {
        Msn = $"MSN-{i:D6}",
        Manufacturer = i % 2 == 0 ? "Boeing" : "Airbus",
        IsActive = true,
        FirstFlightDate = DateTime.Now.AddDays(-i),
        NextMaintenanceDate = DateTime.Now.AddMonths(6),
        Capacity = 150 + (i % 50),
        TotalFlightHours = i * 10.5,
        FuelCapacity = 5000f,
        OriginalPrice = 50_000_000m + (i * 1000),
        SiteId = (i % 5) + 1,
        CurrentAirportId = (i % 10) + 1
    });
}

// Add using batches of 50
int addedCount = await this.Repository.MassAddAsync(newPlanes, batchSize: 50);

// Add using bulk operations if supported
int bulkAddedCount = await this.Repository.MassAddAsync(newPlanes, useBulk: true);
Console.WriteLine($"Added {addedCount} planes using batch operations");
```

### When to Use
- Initial data seeding
- Data migration from external systems
- Importing large datasets
- Test data generation

## 5. MassUpdateAsync

### Purpose
Updates a large number of existing entities efficiently using batching or bulk operations.

### Method Signature
```csharp
Task<int> MassUpdateAsync(IEnumerable<TEntity> items, int batchSize = 100, bool useBulk = false, bool useSetModified = false)
```

### Parameters
- **items**: Collection of entities to update (must have valid IDs)
- **batchSize**: Number of entities to process per batch (default: 100)  
- **useBulk**: Whether to use database bulk update if supported (default: false)
- **useSetModified**: if set to true, use loop + SetModified rather than UpdateRange. (default: false) UpdateRange marks each provided entity and its related/child entities as Modified, whereas SetModified marks only the specified entity as Modified.


### Returns
Number of entities successfully updated

### How It Works
1. If bulk operations are supported and enabled, uses database-specific bulk update
2. Otherwise, processes entities in batches using `UpdateRange`
3. Each batch is committed separately
4. Context is reset between batches for memory management

### Example with Planes
```csharp
// Update maintenance schedules for existing planes
var planesToUpdate = await this.Repository.GetAllEntityAsync(
    filter: p => p.IsActive && p.NextMaintenanceDate < DateTime.Now.AddDays(30)
);

var planesList = planesToUpdate.ToList();
foreach (var plane in planesList)
{
    plane.NextMaintenanceDate = plane.NextMaintenanceDate.AddMonths(6);
    plane.TotalFlightHours += 100; // Add flight hours
    if (plane.FuelLevel.HasValue)
        plane.FuelLevel = Math.Max(plane.FuelLevel.Value - 50, 0); // Consume fuel
}

// Update in batches of 25
int updatedCount = await this.Repository.MassUpdateAsync(planesList, batchSize: 25);

// Update using bulk operations
int bulkUpdatedCount = await this.Repository.MassUpdateAsync(planesList, useBulk: true);
Console.WriteLine($"Updated {updatedCount} planes");
```

### When to Use
- Periodic maintenance updates
- Batch processing of business logic changes
- Data synchronization between systems
- Performance-critical updates of large datasets

## 6. MassDeleteAsync

### Purpose
Deletes a large number of entities efficiently with multiple deletion strategies.

### Method Signature
```csharp
Task<int> MassDeleteAsync(IEnumerable<TEntity> items, int batchSize = 100, bool useBulk = false, bool useExecuteDelete = true)
```

### Parameters
- **items**: Collection of entities to delete
- **batchSize**: Number of entities to process per batch (default: 100)
- **useBulk**: Whether to use database bulk delete if supported (default: false)
- **useExecuteDelete**: Whether to use `ExecuteDeleteAsync` instead of `RemoveRange` (default: true)

### Returns
Number of entities successfully deleted

### How It Works
1. If bulk operations are supported and enabled, uses database bulk delete
2. If `useExecuteDelete` is true, extracts IDs and calls `DeleteByIdsAsync`
3. Falls back to batched `RemoveRange` operations
4. Each strategy optimizes for different scenarios

### Example with Planes
```csharp
// Delete old, inactive planes
var planesToDelete = await this.Repository.GetAllEntityAsync(
    filter: p => !p.IsActive && p.LastFlightDate < DateTime.Now.AddYears(-10)
);

var deleteList = planesToDelete.ToList();

// Method 1: Using ExecuteDelete
int deletedCount1 = await this.Repository.MassDeleteAsync(
    deleteList, 
    batchSize: 50, 
    useExecuteDelete: true
);

// Method 2: Using bulk operations
int deletedCount2 = await this.Repository.MassDeleteAsync(
    deleteList, 
    useBulk: true
);

// Method 3: Using traditional RemoveRange
int deletedCount3 = await this.Repository.MassDeleteAsync(
    deleteList, 
    batchSize: 25, 
    useBulk: false, 
    useExecuteDelete: false
);

Console.WriteLine($"Deleted {deletedCount1} old planes");
```

### When to Use
- Data archival and cleanup
- Removing obsolete records
- Processing deletion queues
- Cleanup operations based on complex business rules
 