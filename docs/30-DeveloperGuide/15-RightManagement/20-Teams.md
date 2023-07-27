---
layout: default
title: Teams
parent: Right management
grand_parent: Developer guide
nav_order: 20
---

# Teams
This file explains what teams are and how to add new type of team to your project.

## What is a team?
A team is an item on which we give roles to users.
Therefore, when you add a new type of team you can create many teams of this type and add members with roles of those teams.

The initial generation of the project, generate a default type of team. It is the type "Site".
You can start the application and go in Site menu to understand the usage.

## Back

You can duplicate the files of Site elements and replace Site by the name of your team.
You have: 
- Infrastructure.Data\ModelBuilders\SiteModelBuilder.cs
- Domain\SiteModule\ ...
- Domain.Dto\Site\ ...
- Application\Site\ ...
- Presentation.Api\Controllers\Site\SitesController.cs

And similar to [CRUD_Back](../40-Back/70-CreateACRUD.md) the basic right just be added in
- CrossCutting.Common\Right.cs
- Presentation.Api\bianetconfig.json
  
For injection similar to [CRUD_Back](../40-Back/70-CreateACRUD.md) update:
- Crosscutting.Ioc\IocContainer.cs:
    => Into the “ConfigureApplicationContainer” function add a Transient on the service.

In addition, to finish update the database.

## Front
The procedure is similar to the [CRUD_Front](../30-Front/20-CreateACRUD.md) but you will use the zip **aircraft-maintenance-companies.zip** instead of **feature-planes.zip**
