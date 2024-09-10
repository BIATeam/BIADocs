---
sidebar_position: 1
---
# Package a new version of the Framework (Only for BIATeam):

## Refine the BIADemo project
- In the .Net Part: put comments "// BIADemo only" at the beginning of each file which must not appear in the template
- Put behind comments "// Begin BIADemo" and "// End BIADemo" the parts of the files to make disappear in the template
- Update all nugets based on the .Net Core version of the project.
- Remove all warnings in .Net core.
- Update npm package
  - In the **package.json** file, under **dependencies** and **devDependencies**, if they are not there, add an **^** next to the version number for all packages except for packages **rxjs**, **ts-node** and **typescript** or you will put a **~**. Example: "primeng": "^16.9.1", "rxjs": "~7.8.1",
  - launch the cmd **npm outdated**
  - Edit the **package.json** file to replace the **Current** version with the **Wanted** version
  - Delete the **package-lock.json** file
  - Launch the command **npm install**
  - In the package.json file, under dependencies and devDependencies, delete all **^** and **~**. Example: "primeng": "16.9.1", "rxjs": "7.8.1",
- Ng lint the angular project and remove all errors and warnings. From version >= 3.9, run the command **npm run clean**
- Change the framework version in 
  - **..\BIADemo\DotNet\TheBIADevCompany.BIADemo.Crosscutting.Common\Constants.cs**
  - **..\BIADemo\Angular\src\app\shared\bia-shared\framework-version.ts**
- Verify the project version should be 0.0.0 in
  - **..\BIADemo\DotNet\TheBIADevCompany.BIADemo.Crosscutting.Common\Constants.cs**
  - **..\BIADemo\Angular\src\environments\all-environment.ts**
- If it is a major version modify it in 
  - **..\BIADemo\DotNet\Switch-To-Nuget.ps1**
- If the year change update footer :
  - **..\BIADemo\Angular\src\app\shared\bia-shared\components\layout\classic-footer\classic-footer.component.html**
  - And Replace all copyright ex: ```<Copyright>Copyright © TheBIADevCompany 2024</Copyright>``` by ```<Copyright>Copyright © TheBIADevCompany 2025</Copyright>```
- Test Authentication AD Group + ReadOnly Database + Unitary Test
- COMMIT BIADemo
- Test a deployment in INT, UAT and PRD.

## Compile the BIA packages:
- Change the version number of all BIA.Net.Core packages to match the version to be released:
  - ex : Replace All ```<Version>3.9.0</Version>``` by ```<Version>3.10.0</Version>```
- If the year change change the copyright:
  - ex : Replace all ```<Copyright>Copyright © BIA 2024</Copyright>``` by ```<Copyright>Copyright © BIA 2025</Copyright>```
- Compile the whole solution in release
- Publish all the packages (right click on each project, publish, "Copy to NuGetPackage folder", Publish)

## Switch the BIADemo project to nuget
- In the file **...\BIADemo\DotNet\Switch-To-Nuget.ps1** adapt the package version number in the line :
    ```
    dotnet add $ProjectFile package BIA.Net.Core.$layerPackage -v 3.5.*
    ```
- In Visual Studio select the local Package source (on your folder ...\BIADemo\DotNet\BIAPackage\NuGetPackage)
- Start the script **...\BIADemo\DotNet\Switch-To-Nuget.ps1**
- Check that the solution compiles (need to have configured a local source nuget to ...\BIADemo\BIAPackage\NuGetPackage)
- test the BIADemo project.
- Remark: If after this step you have to perform change in the package you should clean the local nuget cache and reinstall package:
  - delete bia.net.core.* files in C:\Users\\[username]\\.nuget
  - force reinstall package: Update-Package -reinstall
  - and rebuild all.

## Prepare BIATemplate:
- Synchronize your BIATemplate local folder with github.
- Stop the BIATemplate IIS process.
- Launch **...\BIADemo\Tools\1-Angular-BIADemo-BIATemplate.ps1** (if some files are to exclude modify the script)
- Launch **...\BIADemo\Tools\2-DotNet-BIADemo-BIATemplate.ps1**
- Disable the serviceWorker in the angular.json file : ```"serviceWorker": false```
- Compile the solution BIATemplate, Test and verify the absence of warning.
- Copy the file DataModel.drawio from BIADemo to BIATemplate
  
## Prepare BIACompany Files and release BIATemplate:
- Synchronize your BIACompanyFiles local folder with github.
- Copy the last version folder in   **..\BIACompanyFiles** to **..\BIACompanyFiles\VX.Y.Z**
- Launch **...\BIADemo\Tools\3-DeliverBIATemplateAndCompanyFileVersion.ps1**
- Verify that you have the json files in **..\CompanyFiles\VX.Y.Z\DotNet\TheBIADevCompany.BIATemplate.Presentation.Api**


## Test the project creation using the VX.Y.Z
- With the BIAToolKit create a project of the VX.Y.Z.
- Test it.
- If is is ok rename **...\BIACompanyFiles\VX.Y.Z** with the good version name

## Publish BIAPackage
- If everything is ok Publish the packages on nuget.org
- Wait the confirmation by mail of all packages
- COMMIT BIADemo, BIACompanyFiles and BIATemplate

## ONLY FOR LATEST VERSION (ie : not for patch) - Publish the demo site:
- Launch in the terminal of VSCode in **...BIADemo\Angular** folder:
```
npm run deploy
```

## Deliver the version
- Create a release of the version in the 3 repository BIADocs, BIADemo and BIATemplate
- Post message for developers, to inform than a new version is available.

## Prepare Migration
- Follow those steps: [PREPARE MIGRATION](./10-PrepareMigration.md)