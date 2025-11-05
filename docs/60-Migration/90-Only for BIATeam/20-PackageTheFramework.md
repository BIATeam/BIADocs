---
sidebar_position: 20
---
# Package a new version of the Framework

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
  - Launch the command **npm audit fix**
  - In the package.json file, under dependencies and devDependencies, replace all **^** by **~**. Example: "primeng": "~16.9.1", "rxjs": "~7.8.1",
- Ng lint the angular project and remove all errors and warnings. From version >= 3.9, run the command **npm run clean**
- Change the framework version in 
  - **..\BIADemo\DotNet\TheBIADevCompany.BIADemo.Crosscutting.Common\Constants.cs**
  - **..\BIADemo\Angular\packages\bia-ng\framework-version.ts**
  - **..\BIADemo\Angular\packages\bia-ng\package.json**
- If it is a major or minor version (first or second digit modification) modify it in 
  - **..\BIADemo\DotNet\Switch-To-Nuget.ps1**
- If the year change update footer :
  - **..\BIADemo\Angular\src\app\shared\bia-shared\components\layout\classic-footer\classic-footer.component.html**
  - **..\BIADemo\Angular\src\app\shared\bia-shared\components\layout\ultima\footer\ultima-footer.component.html**
  - And Replace all copyright ex: ```<Copyright>Copyright © TheBIADevCompany 2024</Copyright>``` by ```<Copyright>Copyright © TheBIADevCompany 2025</Copyright>```
- Test Authentication AD Group + ReadOnly Database + Unitary Test

## Run BIAToolkit Templates Unit Tests
- Follow the instructions of the following [chapter](./10-Templates/20-BIAToolKitTemplates.md#unit-tests)
- If any differences, fix both templates into BIAToolKit and reference files into BIADemo
:::warning
All tests must be validated before continuing package process !
:::

## Publish bia-ng:
- Move your terminal location to Angular folder : cd Angular
- Switch the angular application to use bia-ng references in imports by executing the switch-to-bia-ng.ps1 script.
- Build the bia-ng lib by executing : ng build bia-ng --production
- Start the application and fix errors if needed.
- Publish the lib by executing :
  - cd dist/bia-ng
  - npm publish --access public
- Update the dependency to bia-ng in package.json by the new version.

# Test the deployment:
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
- In Visual Studio select the local Package source (on your folder ...\BIADemo\DotNet\BIAPackage\NuGetPackage) by going to Nuget Package manager, then click on the config wheel on the top right and adding a new Package Source
- Start the script **...\BIADemo\DotNet\Switch-To-Nuget.ps1**
- Check that the solution compiles (need to have configured a local source nuget to ...\BIADemo\BIAPackage\NuGetPackage)
- test the BIADemo project.
- Remark: If after this step you have to perform change in the package you should clean the local nuget cache and reinstall package:
  - delete bia.net.core.* files in C:\Users\\[username]\\.nuget
  - force reinstall package: Update-Package -reinstall
  - and rebuild all.

## Prepare BIATemplate:
:::tip
Use [BIA Template Documentation](./10-Templates/10-BIATemplates.md) to help you with elements to include/exclude for the final BIA Template.
:::

- Synchronize your BIATemplate local folder with github.
- Stop the BIATemplate IIS process.
- Launch **...\BIADemo\Tools\0-Common-BIADemo-BIATemplate.ps1** (if some additional files are to include modify the script)
- Launch **...\BIADemo\Tools\1-Angular-BIADemo-BIATemplate.ps1** (if some files are to exclude modify the script)
- Launch **...\BIADemo\Tools\2-DotNet-BIADemo-BIATemplate.ps1**
- Disable the serviceWorker in the angular.json file : ```"serviceWorker": false```
- Compile the solution BIATemplate, Test and verify the absence of warning.
- Copy the file DataModel.drawio from BIADemo to BIATemplate
  
## Prepare BIACompany Files and release BIATemplate:
- Synchronize your BIACompanyFiles local folder with github.
- Move your BIACompanyFiles folder beside BIADemo and BIATemplate if not already here
- If an up to date folder of your version is already created in BIACompany files, stop this chapter here
- Copy the last version folder in   **..\BIACompanyFiles** to **..\BIACompanyFiles\VX.Y.Z**
- Launch **...\BIADemo\Tools\3-DeliverBIATemplateAndCompanyFileVersion.ps1**
- Verify that you have the json files in **..\CompanyFiles\VX.Y.Z\DotNet\TheBIADevCompany.BIATemplate.Presentation.Api**

## Test the project creation using the VX.Y.Z
- With the BIAToolKit create a project of the VX.Y.Z whith your version of CompanyFiles or VX.Y.Z of companyFiles.
- Test it.
- If it is ok and you have a VX.Y.Z folder, rename **...\BIACompanyFiles\VX.Y.Z** with the good version name
:::tip
If you have to fix anything into **BIADemo** to resolve project creation issue related to the **BIA Template**, restart process from the [Prepare BIA Template chapter](#prepare-biatemplate)
:::

## Publish BIAPackage
- Redact the change log of the new version
- If everything is ok Publish the packages by connection on nuget.org and use the change log in the comments of each package. You will need an account with authorization on the packages repository.
- Wait the confirmation by mail of all packages
- Use GitFlow extension in VSCode to release the project BIADemo, BIACompanyFiles and BIATemplate use the version name like (V4.0.0)

## Publish the documentation: 
- On project BIADoc run the command:
```
npm run docusaurus docs:version 4.0.0
```
- Use GitFlow extension in VSCode to release the project BIADoc.

## ONLY FOR LATEST VERSION (ie : not for patch) - Publish the demo site:
- Launch in the terminal of VSCode in **...BIADemo\Angular** folder:
```
npm run deploy
```

## Deliver the version
- On the GitHub webSite. Create a release of the version in the 3 repository BIADocs, BIADemo and BIATemplate
- Post message for developers, to inform that a new version is available.

## Prepare Migration
- Follow those steps: [PREPARE MIGRATION](./30-PrepareMigration.md)