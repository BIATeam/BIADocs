---
layout: default
title: Package the Framework
parent: Migrate an existing project
nav_order: 90
has_children: true
---
# Package a new version of the Framework (Only for BIATeam):

## Refine the BIADemo project
- In the .Net Part: put comments "// BIADemo only" at the beginning of each file which must not appear in the template
- Put behind comments "// Begin BIADemo" and "// End BIADemo" the parts of the files to make disappear in the template
- Remove all warnings in .Net core.
- Ng lint the angular poject and remove all errors and warnings.
- Change the framework version in 
  - **..\BIADemo\DotNet\TheBIADevCompany.BIADemo.Crosscutting.Common\Constants.cs**
  - **..\BIADemo\Angular\src\app\shared\bia-shared\framework-version.ts**
- Verify the project version should be 0.0.0 in
  - **..\BIADemo\DotNet\TheBIADevCompany.BIADemo.Crosscutting.Common\Constants.cs**
  - **..\BIADemo\Angular\src\environments\environment.ts**
  - **..\BIADemo\Angular\src\environments\environment.prod.ts**
- If it is a major version modify it in 
  - **..\BIADemo\DotNet\Switch-To-Nuget.ps1**
- If the year change update footer :
  - **..\BIADemo\Angular\src\app\shared\bia-shared\components\layout\classic-footer\classic-footer.component.html**
- Test Authent AD Group + ReadOnly Database + Unitary Test
- COMMIT BIADemo
- Test a deployement in INT, UAT and PRD.

## Compile the BIA packages:
- Change the version number of all BIA.Net.Core packages to match the version to be released.
- Compile the whole solution in release
- Publish all the packages (right click on each project, publish, "Copy to NuGetPackage folder", Publish)

## Switch the BIADemo project to nuget
- In the file **...\BIADemo\DotNet\Switch-To-Nuget.ps1** adapt the package version number in the line :
    ```
    dotnet add $ProjectFile package BIA.Net.Core.$layerPackage -v 3.5.*
    ```
- In Visual Studio select the local 
- Start the script **...\BIADemo\DotNet\Switch-To-Nuget.ps1**
- Check that the solution compiles (need to have configured a local source nuget to ...\BIADemo\BIAPackage\NuGetPackage)
- test the BIADemo project.

## Prepare BIATemplate:
- Synchronize your BIATemplate local folder with github.
- Launch **...\BIADemo\Tools\1-Angular-BIADemo-BIATemplate.ps1** (if some files are to exclude modify the script)
- Launch **...\BIADemo\Tools\2-DotNet-BIADemo-BIATemplate.ps1**
- Compile the solution BIATemplate, Test and verify the absence of warning.

## Prepare BIACompany Files and release BIATemplate:
- Synchronize your BIACompanyFiles local folder with github.
- Copy the last version folder in   **..\BIACompanyFiles** to **..\BIACompanyFiles\VX.Y.Z**
- Launch **...\BIADemo\Tools\3-DeliverBIATemplateAndCompanyFileVersion.ps1**
- Verirfy that you have the json files in **..\CompanyFiles\VX.Y.Z\DotNet\TheBIADevCompany.BIATemplate.Presentation.Api**


## Test the project creation using the VX.Y.Z
- With the BIAToolKit create a project of the VX.Y.Z.
- Test it.
- If is is ok rename **...\BIACompanyFiles\VX.Y.Z** with the good version name

## Publish BIAPackage
- If everything is ok Publish the packages on nuget.org
- Wait the confirmation by mail of all packages
- COMMIT BIADemo, BIACompanyFiles and BIATemplate

## Publish the demo site:
- Launch in the terminal of VSCode in **...BIADemo\Angular** folder:
```
npm run deploy
```

## Deliver the version
- Create a release of the version in the 3 repository BIADocs, BIADemo and BIATemplate
- Mail all developer to informe than a new version is available.

## Prepare Migration
- Follow those steps: [PREPARE MIGRATION](./PREPARE%20MIGRATION.md)