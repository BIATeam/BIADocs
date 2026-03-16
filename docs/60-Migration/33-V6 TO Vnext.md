---
sidebar_position: 1
---

import CheckItem from '@site/src/components/CheckItem';
import CollapsibleCode from '@site/src/components/CollapsibleCode';

# V6 to Vnext

## Pre-instructions
### Move EF Core migrations
:::warning
Mandatory step to prepare the usage of the new architecture with dedicated projects for EF Core migrations.  
See [documentation](../40-DeveloperGuide/10-Start/50-InfrastructureDataProject.md)
:::

1. Copy the following powershell script into a new `.ps1` file on your computer

<CollapsibleCode maxLines={5}>

```powershell title="MoveMigrationsEF.ps1"
function Move-MigrationFiles {
  param (
    [string]$SourceDir,
    [string]$DestDir,
    [string]$OldNamespace,
    [string]$NewNamespace,
    [string]$Label
  )

  if (-not (Test-Path $SourceDir)) {
    Write-Host "$Label : source folder not found, skipping: $SourceDir" -ForegroundColor Yellow
    return
  }

  $files = Get-ChildItem -Path $SourceDir -File -Filter "*.cs"
  if ($files.Count -eq 0) {
    Write-Host "$Label : no .cs files found in source folder, skipping." -ForegroundColor Yellow
    return
  }

  Write-Host "`n$Label : moving $($files.Count) .cs file(s) from '$SourceDir' to '$DestDir'" -ForegroundColor Cyan

  if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
  }

  foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $updatedContent = $content -replace [regex]::Escape($OldNamespace), $NewNamespace
    $destFile = Join-Path $DestDir $file.Name
    [System.IO.File]::WriteAllText($destFile, $updatedContent, [System.Text.Encoding]::UTF8)
    Remove-Item -Path $file.FullName -Force
    Write-Host "  Moved & updated namespace: $($file.Name)" -ForegroundColor Green
  }

  Write-Host "$Label : done." -ForegroundColor Green
}

function Move-EfMigrationsToProjects {
  param (
    [string]$SourceBackEnd
  )

  # Find the Infrastructure.Data project folder (direct child whose name ends with .Infrastructure.Data)
  $infraDataFolder = Get-ChildItem -Path $SourceBackEnd -Directory |
    Where-Object { $_.Name -match '\.Infrastructure\.Data$' } |
    Select-Object -First 1

  if ($null -eq $infraDataFolder) {
    Write-Host "Infrastructure.Data project folder not found in $SourceBackEnd" -ForegroundColor Red
    return
  }

  $infraDataProjectName = $infraDataFolder.Name
  Write-Host "Found Infrastructure.Data project: $infraDataProjectName" -ForegroundColor Cyan

  # Locate destination migration projects (direct children of SourceBackEnd)
  $sqlServerProjectFolder = Get-ChildItem -Path $SourceBackEnd -Directory |
    Where-Object { $_.Name -eq "$infraDataProjectName.Migrations.SqlServer" } |
    Select-Object -First 1

  $postgreSqlProjectFolder = Get-ChildItem -Path $SourceBackEnd -Directory |
    Where-Object { $_.Name -eq "$infraDataProjectName.Migrations.PostgreSQL" } |
    Select-Object -First 1

  # SQL Server: Migrations -> *.Migrations.SqlServer\Migrations
  if ($null -ne $sqlServerProjectFolder) {
    Move-MigrationFiles `
      -SourceDir    (Join-Path $infraDataFolder.FullName "Migrations") `
      -DestDir      (Join-Path $sqlServerProjectFolder.FullName "Migrations") `
      -OldNamespace "$infraDataProjectName.Migrations" `
      -NewNamespace "$infraDataProjectName.Migrations.SqlServer.Migrations" `
      -Label        "SqlServer"
  }
  else {
    Write-Host "SQL Server destination project not found: $infraDataProjectName.Migrations.SqlServer" -ForegroundColor Red
  }

  # PostgreSQL: MigrationsPostGreSql -> *.Migrations.PostgreSQL\Migrations
  if ($null -ne $postgreSqlProjectFolder) {
    Move-MigrationFiles `
      -SourceDir    (Join-Path $infraDataFolder.FullName "MigrationsPostGreSql") `
      -DestDir      (Join-Path $postgreSqlProjectFolder.FullName "Migrations") `
      -OldNamespace "$infraDataProjectName.MigrationsPostGreSql" `
      -NewNamespace "$infraDataProjectName.Migrations.PostgreSQL.Migrations" `
      -Label        "PostgreSQL"
  }
  else {
    Write-Host "PostgreSQL destination project not found: $infraDataProjectName.Migrations.PostgreSQL" -ForegroundColor Red
  }

  # Delete the old Infrastructure.Data project folder now that migrations have been moved
  Write-Host "`nDeleting old project folder: $($infraDataFolder.FullName)" -ForegroundColor Cyan
  Remove-Item -Path $infraDataFolder.FullName -Recurse -Force
  Write-Host "Old Infrastructure.Data project folder deleted." -ForegroundColor Green
}

Move-EfMigrationsToProjects -SourceBackEnd "C:\sources\Project\DotNet"
```

</CollapsibleCode>

2. Update at the end the value of the `-SourceBackEnd` by your own path
3. Open a powershell console from your script location
4. Run the script (ex: `.\MoveMigrationsEF.ps1`)
5. Check if all your migrations have been migrated successfully with the namespace updated according to the new location
6. ⚡**COMMIT**


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
  - `TheBIADevCompany.BIADemo.Crosscutting.Ioc/Bia/IocContainer.cs` **This file is part of the framework and should never be modified**
  - `TheBIADevCompany.BIADemo.Crosscutting.Ioc/IocContainer.cs` **Only this file should contain your project customizations**

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
