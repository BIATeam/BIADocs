---
layout: default
title: Migrate an existing project
nav_order: 60
has_children: true
---

# Migrate the framework version of an existing project

## Check the framework version of you project:
* Open your project file ..\DotNet\\[YourCompanyName].[YourProjectName].Crosscutting.Common\Constants.cs
* Read the value of FrameworkVersion

## Apply successively the migration:
1. Use the BIAToolKit to apply the migration.
2. Manage the conflict (2 solutions)
   1. In BIAToolKit click on "4 - merge Rejected"
      * Search `<<<<<` in all files.
      * Resolve the conflict manually.
   2. Analyze the .rej file (search "diff a/" in VS code) that have been created in your project folder
      * Apply manually the change.
3. Refresh the nuget package version with the command (to launch in visual studio > Package Manager Console):
   ```dotnet restore --no-cache```
4. Follow the detailed steps describe in all files corresponding to your migration.
   * If several steps are passed during the migration apply them successively.
    
