---
layout: default
title: Develop application
parent: Work with BIA
nav_order: 20
---

# Development an application

This methodology is model-driven.

## Build the model
The analyze of the mockup will give an overview of the model to implement.
- Every object manipulated in screens correspond generally to a table.
- The relation between the table should be determine (0-1, 0-\*, 1-\* or \*-\*)
  
At that moment the notion of right will be introduce :
- There is only 3 types of table
  - The “parameters” tables (only change at deployment or by global application administrator)
  - The “teams” tables that give roles on some users.
  - The “items” tables that should be link to at least one team table.
  - The “technical” tables that are full automatically (like audit, replication...).
- To respect this organization it is recommended to draw the database model in a modeling tool like draw io.
  - Draw the team table at the top and items table below.
  - You should see at lease a link that start from every item table and arrive to a team table. (it can pass by relation with others item table)

![BIADemo Data Model](../../Images/DataModel.dark.png)


=> At this step some review can be done with business to ensure there are agree with the model.

## Implement quickly model and CRUD.
Now you can generate all CRUDs corresponding to all table that will be fill manually.
- The implementation of a CRUD is not costly and even if it is not present in the mockup, it can be a start point for complex screen.
- To implement CRUD quickly follow the documentation [CRUD](../30-DeveloperGuide/20-Features/20-CRUD/CRUD.md)

=> At this step some business team can be interested to play with the application as is. The data model is more understandable and they can validate or rectify it, before than more complex dev begin.

## Customize the app
The huge of the development can begin to give to the application an efficiency and the best added value for the business:
- Some screens can now be redesign, by adding components or other features. (To be more ergonomic, efficient or just smarter)
- In the WebApi, implement some business rules. (Like cascade creation/deletion, control of the validity, versioning, Manuel import with control)
- In the Service, implement the heavy and/or planned treatments. (Like automatic import, export, synchronization, computation, archiving ...)
