---
layout: default
title: Migrate an existing project
nav_order: 70
has_children: true
---

# Migrate the framewok version of an existing project

## Check the framework version of you project:
* Open your project file ..\DotNet\\[YourCompanyName].[YourProjectName].Crosscutting.Common\Constants.cs
* Read the value of FrameworkVersion

## Apply successively the migration:
* If your project is older than V3.4.0 use this [doc](./3.3.3%20TO%203.4.0.html).
* Else use the BIAToolKit to apply the migration.
  * Follow the detailled step describe in all files corresponding to your migration:
{: .fs-6 .fw-300 }