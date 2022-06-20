---
layout: default
title: Migrate an existing project
nav_order: 50
has_children: true
---

# Migrate the framewok version of an existing project

## Check the framework version of you project:
* Open your project file ..\DotNet\\[YourCompanyName].[YourProjectName].Crosscutting.Common\Constants.cs
* Read the value of FrameworkVersion

## Apply successively the migration:
1. Use the BIAToolKit to apply the migration.
2. Manage the confict (2 solutions)
   1. In BIAToolKit click on "4 - merge Rejected"
      * Search "<<<<<" in all files.
      * Resolve the conflit manualy.
   2. Analyse the .rej file (search "diff a/" in VS code) that have been created in your project folder
      * Apply manualy the change.
3. Refresh the nuget package version with the command (to launch in visual sudion > Package Manager Console):
   ```dotnet restore --no-cache```
4. Follow the detailled steps describe in all files corresponding to your migration.
   * If several steps are passed durring the migration apply them succesively.
    
{: .fs-6 .fw-300 }