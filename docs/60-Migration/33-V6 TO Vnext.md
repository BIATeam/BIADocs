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
        ExcludedServiceNames = null, // Add here
        IncludedServiceNames = null, // Add here
    };
}
```

#### 4) DbContext

The configuration of the DbContext (via collection.AddDbContext) has been moved to the method `BiaConfigureInfrastructureDataContainerDbContext`. This method is minimally configurable with the following input parameters:
- string dbKey = BiaConstants.DatabaseConfiguration.DefaultKey
- bool enableRetryOnFailure = true
- int commandTimeout = default (30s)

### ModelBuilder

This change was made to simplify future migrations. Please take the time to read the explanations below start merge.

#### 1) What changed
- Model builders were refactored to split:
  - entity structure (`Create...Model`)
  - seed data (`Create...ModelData`)
- `CreateModel(...)` now calls both structure and data methods explicitly.
- BIA code moved into partial files (**These files must never be modified**):
  - `ModelBuilders/Bia/UserModelBuilder.cs`
  - `ModelBuilders/Bia/TranslationModelBuilder.cs`
- Main model builder classes keep project-specific logic.

#### 2) Main impacted classes
- `BaseUserModelBuilder`
- `BaseTranslationModelBuilder`
- `BaseNotificationModelBuilder`
- `NotificationModelBuilder`

#### 3) Framework Migration
During framework migration, you must follow this pattern by separating the code that creates the entity structure from the code that initializes the data. You need to ensure that any code moved into the classes now contained in the ModelBuilders/Bia folder no longer appears in your ModelBuilders.
If you do not wish to use the data initialization provided by BIA, you can comment out the code that starts with `base.`.

#### 4) Test Framework Migration
These changes should not result in any database migration. To verify this, simply create a test Entity Framework migration—it should be empty.

