---
layout: default
title: Create a CRUD
parent: Back
grand_parent: Developer guide
nav_order: 70
---

# Create a CRUD
This document explains how to quickly create a CRUD Rest API from zero.
It means that you will see all the files to be modified from the DB mapping to the controller:
- Into the Domain layer you have to code an Entity corresponding to your table in the database.
- Into the Infracstructure Layer, you have to code the mapping between the database and the new entity.
- Into the Application Layer, you have to code a new service to manage the operations done on the entity.
  - Create,
  - Read or Querying with or without filter, pagination,
  - Update
  - Delete.
- Into the Presentation Layer, you have to code the Rest API corresponding to the CRUD operations.
  
<u>For this example, we imagine that we want to create a new feature with the name: <span style="background-color:#327f00">Plane</span>.   </u>


## Prerequisite
The database is created.

## Create the entity
### Aggregate folder 
The first code to write is the Entity. The entity have to located into a Module folder and a Aggregate folder.
The Aggregate folder can content several entity. The concept of Aggregate come from Domain Driven Design. 
In summary, we can considerate that an entity in relationship with the main entity of an aggregate can be remove when the main entity is deleted.

![Entity folder](../../../Images/EntityPath.jpg)

### Code
The entity class have to inherit of VersionnedTable and IEntity which is parametrized by key type.

#### Team constraint
The Bia Framework provides for data segregation and user role managment by Team. So all entity must be :
- either an other entity as parent 
- or a entity reprensenting a Team.
  
Here the entity representing a Team is Site.
With this segregation, a Plane created by a user of site A cannot be consulted by a user of an other site B.

For Team concept consult the specific page [Team](../10-RightManagement/20-Teams.md) 

```csharp
// BIADemo only
// <copyright file="Plane.cs" company="TheBIADevCompany">
//     Copyright (c) TheBIADevCompany. All rights reserved.
// </copyright>

namespace TheBIADevCompany.BIADemo.Domain.PlaneModule.Aggregate
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations.Schema;
    using BIA.Net.Core.Domain;
    using TheBIADevCompany.BIADemo.Domain.SiteModule.Aggregate;

    /// <summary>
    /// The plane entity.
    /// </summary>
    public class Plane : VersionedTable, IEntity<int>
    {
        /// <summary>
        /// Gets or sets the id.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Gets or sets the Manufacturer's Serial Number.
        /// </summary>
        public string Msn { get; set; }

        ...

        /// <summary>
        /// Gets or sets the site id.
        /// </summary>
        public int SiteId { get; set; }

    }
}
```

## Model Builder code 
Now the entity is created, we can create the ModelBuilder file corresponding into the InfrastructureData project. 
Each feature has a ModelBuilder file prefixed by the name of the feature. For example PlaneModelBuilder.cs.

Theses files are included into the DataContext file.

Here you can see the exemple of Plane Model Builder file.
As an aggregate can have several classes, a modelBuilder file can describ several tables.


```csharp
namespace TheBIADevCompany.BIADemo.Infrastructure.Data.ModelBuilders
{
    using Microsoft.EntityFrameworkCore;
    using Microsoft.Extensions.Hosting;
    using TheBIADevCompany.BIADemo.Domain.PlaneModule.Aggregate;

    /// <summary>
    /// Class used to update the model builder for plane domain.
    /// </summary>
    public static class PlaneModelBuilder
    {
        /// <summary>
        /// Create the model for projects.
        /// </summary>
        /// <param name="modelBuilder">The model builder.</param>
        public static void CreateModel(ModelBuilder modelBuilder)
        {
            CreatePlaneModel(modelBuilder);
            CreatePlaneTypeModel(modelBuilder);
            CreateAirportModel(modelBuilder);
        }

        /// <summary>
        /// Create the model for planes.
        /// </summary>
        /// <param name="modelBuilder">The model builder.</param>
        private static void CreatePlaneModel(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Plane>().HasKey(p => p.Id);
            modelBuilder.Entity<Plane>().Property(p => p.SiteId).IsRequired(); // relationship 1-*
            modelBuilder.Entity<Plane>().Property(p => p.PlaneTypeId).IsRequired(false); // relationship 0..1-*
            modelBuilder.Entity<Plane>().Property(p => p.Msn).IsRequired().HasMaxLength(64);
            modelBuilder.Entity<Plane>().Property(p => p.IsActive).IsRequired();
            modelBuilder.Entity<Plane>().Property(p => p.LastFlightDate).IsRequired(false);
            modelBuilder.Entity<Plane>().Property(p => p.DeliveryDate).IsRequired(false);
            modelBuilder.Entity<Plane>().Property(p => p.SyncTime).IsRequired(false);
            modelBuilder.Entity<Plane>().Property(p => p.Capacity).IsRequired();
            modelBuilder.Entity<Plane>()
                .HasMany(p => p.ConnectingAirports)
                .WithMany(a => a.ClientPlanes)
                .UsingEntity<PlaneAirport>();
        }

        /// <summary>
        /// Create the model for planes.
        /// </summary>
        /// <param name="modelBuilder">The model builder.</param>
        private static void CreatePlaneTypeModel(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<PlaneType>().HasKey(p => p.Id);
            modelBuilder.Entity<PlaneType>().Property(p => p.Title).IsRequired().HasMaxLength(64);
            modelBuilder.Entity<PlaneType>().Property(p => p.CertificationDate).IsRequired(false);
        }

        /// <summary>
        /// Create the model for aiports.
        /// </summary>
        /// <param name="modelBuilder">The model builder.</param>
        private static void CreateAirportModel(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Airport>().HasKey(p => p.Id);
            modelBuilder.Entity<Airport>().Property(p => p.Name).IsRequired().HasMaxLength(64);
            modelBuilder.Entity<Airport>().Property(p => p.City).IsRequired().HasMaxLength(64);
        }
    }
}
```

## DataContext 
After creating the modelbuilder file, we can modify the DataContext file to :
- add the DBSet
- Add the call to the modelbuilder classe.


```csharp
        /// <summary>
        /// Gets or sets the Plane DBSet.
        /// </summary>
        public DbSet<Plane> Planes { get; set; }

        ...
        /// <inheritdoc cref="DbContext.OnModelCreating"/>
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // modelBuilder.HasDefaultSchema("dbo")
            base.OnModelCreating(modelBuilder);
            ...
            // Begin BIADemo
            PlaneModelBuilder.CreateModel(modelBuilder);
        }
```

The call of modelbuilder classe must be coded after //Begin BIADemo in order to preserve the future Framework evolution.

## DTO code 
The DTO code represente two concept: 
- the data comming from the front,
- the data contained into the ressource managed by a Rest API.
  
In CRUD feature, the Rest API resource contain the same properties of the corresponding entity excepted for the relationship.

A entity with relationships to other entity has a DTO where all relationship as converted to an OptionDto.

For OptionDto concept you can consult the specific page [OptionDto](80-OptionDTO.md) (comming soon).

## Mapper Code
The Mapper contain two methods in order to convert entity to Dto and vice versa.

There is also methods used to filtering during the querying operations.

The method DtoToRecord is used durring the csv extract function to convert entity to csv record.

You can see in PlaneMapper class of BiaDemo poprject how theses methods are implemented.

## Application Service Code
The ApplicationServie code inherit of CrudAppServiceBase which implement all the methods necessary for CRUD operations.
So all the code you have to write is to recover the team to which the entity belongs.

```csharp
    /// <summary>
    /// The application service used for plane.
    /// </summary>
    public class PlaneAppService : CrudAppServiceBase<PlaneDto, Plane, int, PagingFilterFormatDto, PlaneMapper>, IPlaneAppService
    {
        /// <summary>
        /// The current SiteId.
        /// </summary>
        private readonly int currentSiteId;

        /// <summary>
        /// Initializes a new instance of the <see cref="PlaneAppService"/> class.
        /// </summary>
        /// <param name="repository">The repository.</param>
        /// <param name="principal">The claims principal.</param>
        public PlaneAppService(ITGenericRepository<Plane, int> repository, IPrincipal principal)
            : base(repository)
        {
            var userData = (principal as BIAClaimsPrincipal).GetUserData<UserDataDto>();
            this.currentSiteId = userData != null ? userData.GetCurrentTeamId((int)TeamTypeId.Site) : 0;
            this.filtersContext.Add(AccessMode.Read, new DirectSpecification<Plane>(p => p.SiteId == this.currentSiteId));
        }
    }
```

## Controller Code
The Controller inherit of BiaControllerBase and implement all method corresponding to the CRUD operation and more.
You can consult the PlanesController into the BiaDemo project.

Th controller have conditionnal code determinated by the variable <i>UseHubForClientInPlane</i>.
This mean that if define, the controller manage SignalR hub to send message to the client front.

Be carefull to the configuration of signalR URL. On local execution with IIExpress, the url must be like taht : 
```"SignalRUrl": "http://localhost:54321/HubForClients" ```.



## Rigth
The methods into the controller are subject to autorization.
So, you have to add a static class for the new feature into the Rigth.cs file. 
This file is into CrossCutting.Common project.

```csharp
        /// <summary>
        /// The planes rights.
        /// </summary>
        public static class Planes
        {
            /// <summary>
            /// The right to access to the list of planes.
            /// </summary>
            public const string ListAccess = "Plane_List_Access";

            /// <summary>
            /// The right to create planes.
            /// </summary>
            public const string Create = "Plane_Create";

            /// <summary>
            /// The right to read planes.
            /// </summary>
            public const string Read = "Plane_Read";

            /// <summary>
            /// The right to update planes.
            /// </summary>
            public const string Update = "Plane_Update";

            /// <summary>
            /// The right to delete planes.
            /// </summary>
            public const string Delete = "Plane_Delete";

            /// <summary>
            /// The right to save planes.
            /// </summary>
            public const string Save = "Plane_Save";
        }
```

## Permission into biaconfig file
You have to modify the bianetconfig file in order to configure the permissions corresponding to the role:
```csharp
      // Plane
      {
        "Names": [ "Plane_List_Access", "Plane_Read" ],
        "Roles": [ "Admin", "Site_Member" ]
      },
      {
        "Names": [ "Plane_Update", "Plane_Save" ],
        "Roles": [ "Site_Admin" ]
      },
      {
        "Names": [ "Plane_Create", "Plane_Delete" ],
        "Roles": [ "Site_Admin" ]
      },
```
  
## IocContainer
Finaly the last file to change is the IocContainer.

Add this lien into ConfigureApplicationContainer method : 
 ```csharp
 private static void ConfigureApplicationContainer(IServiceCollection collection)
        {
            // Application Layer
            ...

            // Begin BIADemo
            collection.AddTransient<IPlaneAppService, PlaneAppService>();
            // End BIADemo
        }
 ```

## DataBase Update

After that you have to update the database with following commands into Package Manager Console:

```csharp
Add-Migration 'new feature plane' -Context DataContext 
```
and 

```csharp
Update-DataBase -Context DataContext
```
