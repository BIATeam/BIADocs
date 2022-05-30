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
* Use the BIAToolKit to apply the migration.
* Follow the detailled steps describe in all files corresponding to your migration.
  * If several steps are passed durring the migration apply them succesively.
{: .fs-6 .fw-300 }