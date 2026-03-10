---
sidebar_position: 1
---

import CheckItem from '@site/src/components/CheckItem';

# V6 to Vnext



## Back Manual Steps

### IocContainer

To simplify future migrations, the `IocContainer` class has been completely redesigned.

A simple merge is not possible. The best approach is to take the new version and then reapply your project modifications. Please take the time to read the explanations below first.

#### 1) Class structure


Before:
- single class `IocContainer` in one file with all registrations.

Now:
- `IocContainer` is `public static partial class`.
- logic is split between two files:
  - `TheBIADevCompany.BIADemo.Crosscutting.Ioc/Bia/IocContainer.cs` **<= This file is part of the framework and should never be modified**
  - `TheBIADevCompany.BIADemo.Crosscutting.Ioc/IocContainer.cs` **<= Only this file should contain your project customizations**

#### 2) Method signature

Before:
- `ConfigureContainer(IServiceCollection collection, IConfiguration configuration, bool isApi, bool isUnitTest = false)`.

Now:
- `ConfigureContainer(ParamIocContainer param)`.
- dependencies and flags are grouped in `ParamIocContainer` (`Collection`, `Configuration`, `IsApi`, `IsUnitTest`, `BiaNetSection`, etc.).

#### 3) Auto-registration

The new structure separates explicit registrations from assembly auto-registration:
- `BiaConfigureApplicationContainer` + `BiaConfigureApplicationContainerAutoRegister`
- `BiaConfigureDomainContainer` + `BiaConfigureDomainContainerAutoRegister`
- `BiaConfigureInfrastructureDataContainer` + `BiaConfigureInfrastructureDataContainerAutoRegister`

If in your project you had specified `ExcludedServiceNames` or `IncludedServiceNames`, you now need to specify them in `GetGlobalParamAutoRegister`.

``` csharp
private static ParamAutoRegister GetGlobalParamAutoRegister(ParamIocContainer param)
{
    return new ParamAutoRegister()
    {
        Collection = param.Collection,
        ExcludedServiceNames = null,
        IncludedServiceNames = null,
    };
}
```

#### 4) DbContext

The configuration of the DbContext (via collection.AddDbContext) has been moved to the method `BiaConfigureInfrastructureDataContainerDbContext`. This method is minimally configurable with the following input parameters:
- string dbKey = BiaConstants.DatabaseConfiguration.DefaultKey
- bool enableRetryOnFailure = true
- int commandTimeout = default

