---
sidebar_position: 1
---

# Cloning objects in .Net
## Why cloning ?
When an object cannot or must not be altered you can make a perfect copy of it to alter it as you wish, losing all the references to original object.

## Usage
By importing BIA.Net.Core.Common.Extensions your objects will have access to a function cloning the object (if the object can be serialized) and returning that copy.

```csharp
using BIA.Net.Core.Common.Extensions;
public MyItemType DuplicateItemForDb(MyItemType myItem)
{
    MyItemType myItemCopy = myItem.DeepCopy();
    myItemCopy.Id = 0;
    return myItemCopy;
}
```