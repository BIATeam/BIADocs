---
sidebar_position: 120
---

# Read Only Mode

This file explains what the read only mode offers.

## Overview

This mode will provide the best performance when retrieving data from the database. This mode will also allow queries to be made in parallel.

## Usage

To use the readOnly (also called NoTracking in the framework) you just have to pass true to your getAsync function for the parameter isReadOnlyMode.

``` csharp
        this.GetAsync(id: 50247, isReadOnlyMode: true);
```

The consequences of using readonly mode are that the objects you get from the SQL requests aren't tracked by the database context and can't be updated.

With this mode, you can make multiple requests to the same database in parallel (which would not be possible without the no tracking activated).

Here is an example of how to make parallel calls. This example doesn't make any functional sense, it's just an example.
The **GetAsync** method shows a classic call.
The **GetInParallelAsync** method shows a parallel call.

``` csharp
        public async Task GetAsync()
        {
            // We launch here 3 queries one by one and we wait each time for the result
            var obj1 = await this.GetAsync(id: 50247); // 5 seconds
            var obj2 = await this.GetAsync(id: 50248); // 5 seconds
            var obj3 = await this.GetAsync(id: 50249); // 5 seconds

            // If each method takes 5 seconds, we wait 15 seconds to retrieve all our results
        }

        public async Task GetInParallelAsync()
        {
            // We launch here 3 queries in parallel
            var task1 = this.GetAsync(id: 50247, isReadOnlyMode: true); // 5 seconds
            var task2 = this.GetAsync(id: 50248, isReadOnlyMode: true); // 5 seconds
            var task3 = this.GetAsync(id: 50249, isReadOnlyMode: true); // 5 seconds

            var obj1 = await task1;
            var obj2 = await task2;
            var obj3 = await task3;

            // We only wait 5 seconds to retrieve all our results
        }
```
