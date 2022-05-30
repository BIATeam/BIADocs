---
layout: default
title: Audit
parent: Features
grand_parent: Developer guide
nav_order: 7
---

# Audit
This file explains how to activate/desactivate the audit feature (users' modifications tracing) and how to customize it.

## Prerequisite

### Knowledge to have:
The audit feature is actively using the **Audit<area>.NET** library
* [Audit.NET github site](https://github.com/thepirat000/Audit.NET)
* [Audit.NET documentation](https://github.com/thepirat000/Audit.NET/blob/master/README.md)
* [Audit.EntityFramework documentation](https://github.com/thepirat000/Audit.NET/blob/master/src/Audit.EntityFramework/README.md)
* [Audit.NET.SqlServer documentation](https://github.com/thepirat000/Audit.NET/blob/master/src/Audit.NET.SqlServer/README.md)

## Overview
The audit feature, by default, stores the modifications (and the user who has done these modifications) done on entity objects in a dedicated **Events** table of the default database.

## Activation/Deactivation
* to activate/deactivate the feature modify the "IsActive" property in the following part of the bianetconfig file:
```
  "AuditConfiguration": {
    "IsActive": true,
    "ConnectionStringName": "ProjectDatabase"      
  }
```      

## Configuration and Customizing:
* The entities class to be audited shall be specified in the **Infrastructure.Data.Feature.AuditFeature** class (see **Audit<area>.NET** lib documentation for complete description). Uncomment the following part and specify instead the domain entities that you whish to trace :
  `// configurator.Include<Plane>().Include<Airport>();`
* The data provider (database and table where the audit events are stored) can be customized by modifying the lines after this code in the **AuditFeature** class (see **Audit<area>.NET** lib documentation for complete description):
  `Audit.Core.Configuration.Setup()`
* Some custom fields linked to the request scope can be added to the audit event by modifying the following lines in the **AuditFeature** class:
  `Audit.Core.Configuration.AddOnSavingAction(scope =>`


