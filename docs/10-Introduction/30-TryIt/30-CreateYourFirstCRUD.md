---
sidebar_position: 1
---

# Create your first CRUD
We will create in first the feature 'Plane'.

1. Open with Visual Studio 2022 the solution '...\MyFirstProject\DotNet\MyFirstProject.sln'.

2. Create the entity 'Plane':
* In '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain' create 'Plane' folder.
* Create 'Entities' subfolder.
* Create empty class 'Plane.cs' and add: 

```csharp
// <copyright file="Plane.cs" company="MyCompany">
//     Copyright (c) MyCompany. All rights reserved.
// </copyright>

namespace MyCompany.MyFirstProject.Domain.Plane.Entities
{
    using System;
    using System.ComponentModel.DataAnnotations.Schema;
    using BIA.Net.Core.Domain;
    using MyCompany.MyFirstProject.Domain.Site.Entities;

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

        /// <summary>
        /// Gets or sets a value indicating whether the plane is active.
        /// </summary>
        public bool IsActive { get; set; }

        /// <summary>
        /// Gets or sets the last flight date.
        /// </summary>
        public DateTime? LastFlightDate { get; set; }

        /// <summary>
        /// Gets or sets the delivery date.
        /// </summary>
        [Column(TypeName = "date")]
        public DateTime? DeliveryDate { get; set; }

        /// <summary>
        /// Gets or sets the daily synchronization hour.
        /// </summary>
        [Column(TypeName = "time")]
        public TimeSpan? SyncTime { get; set; }

        /// <summary>
        /// Gets or sets the capacity.
        /// </summary>
        public int Capacity { get; set; }
    }
}
```

3. Create the DTO 'PlaneDto':

For more informations about creating a DTO, see [Create a DTO with BIAToolkit documentation](../../30-BIAToolKit/30-CreateDTO.md)

* Open the BIAToolkit
* Go to "Modify existing project" tab
* Set the projects parent path and choose your project
* Go to tab "2 - DTO Generator"
* Select your entity Plane on the list

![FirstCRUD_DTOGenerator_ChooseEntity](../../Images/GettingStarted/FirstCRUD_DTOGenerator_ChooseEntity.PNG)

* Click on "Map to" button
* All the selected properties will be added to the mapping table that represents that properties that will be generated in your corresponding DTO
* Check the required checkbox for the Id mapping property

![FirstCRUD_DTOGenerator_Mapping](../../Images/GettingStarted/FirstCRUD_DTOGenerator_Mapping.PNG)

* Then click the "Generate" button
* The DTO and the mapper will be generated
* Check in the project solution if the DTO and mapper are present

![FirstCRUD_DTOGenerator_Result](../../Images/GettingStarted/FirstCRUD_DTOGenerator_Result.PNG)

4. Complete the Mapper 'PlaneMapper':
* Open the created mapper 'PlaneMapper' 
* Add the override for ExpressionCollection and HeaderName structure :    

```csharp
// <copyright file="PlaneMapper.cs" company="MyCompany">
//     Copyright (c) MyCompany. All rights reserved.
// </copyright>

namespace MyCompany.MyFirstProject.Domain.Plane.Mappers
{
    using System;
    using System.Linq.Expressions;
    using BIA.Net.Core.Domain;
    using MyCompany.MyFirstProject.Domain.Dto.Plane;
    using MyCompany.MyFirstProject.Domain.Plane.Entities;

    /// <summary>
    /// The mapper used for Plane.
    /// </summary>
    public class PlaneMapper : BaseMapper<PlaneDto, Plane, int>
    {
        /// <inheritdoc cref="BaseMapper{TDto,TEntity}.ExpressionCollection"/>
        public override ExpressionCollection<Plane> ExpressionCollection
        {
            // It is not necessary to implement this function if you to not use the mapper for filtered list. In BIADemo it is use only for Calc SpreadSheet.
            get
            {
                return new ExpressionCollection<Plane>
                {
                    { HeaderName.Id, plane => plane.Id },
                    { HeaderName.Msn, plane => plane.Msn },
                    { HeaderName.IsActive, plane => plane.IsActive },
                    { HeaderName.LastFlightDate, plane => plane.LastFlightDate },
                    { HeaderName.DeliveryDate, plane => plane.DeliveryDate },
                    { HeaderName.SyncTime, plane => plane.SyncTime },
                    { HeaderName.Capacity, plane => plane.Capacity },
                };
            }
        }

        [...]

        /// <summary>
        /// Header Name.
        /// </summary>
        public struct HeaderName
        {
            /// <summary>
            /// Header Name Id.
            /// </summary>
            public const string Id = "id";

            /// <summary>
            /// Header Name Msn.
            /// </summary>
            public const string Msn = "msn";

            /// <summary>
            /// Header Name IsActive.
            /// </summary>
            public const string IsActive = "isActive";

            /// <summary>
            /// Header Name LastFlightDate.
            /// </summary>
            public const string LastFlightDate = "lastFlightDate";

            /// <summary>
            /// Header Name DeliveryDate.
            /// </summary>
            public const string DeliveryDate = "deliveryDate";

            /// <summary>
            /// Header Name SyncTime.
            /// </summary>
            public const string SyncTime = "syncTime";

            /// <summary>
            /// Header Name Capacity.
            /// </summary>
            public const string Capacity = "capacity";
        }
    }
}
```

5. Create the ModelBuilder
* In '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Infrastructure.Data\ModelBuilders', create empty class 'PlaneModelBuilder.cs' and add:  

```csharp
namespace MyCompany.MyFirstProject.Infrastructure.Data.ModelBuilders
{
  using Microsoft.EntityFrameworkCore;
  using MyCompany.MyFirstProject.Domain.Plane.Entities;

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
    }

    /// <summary>
    /// Create the model for planes.
    /// </summary>
    /// <param name="modelBuilder">The model builder.</param>
    private static void CreatePlaneModel(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Plane>().HasKey(p => p.Id);
        modelBuilder.Entity<Plane>().Property(p => p.Msn).IsRequired().HasMaxLength(64);
        modelBuilder.Entity<Plane>().Property(p => p.IsActive).IsRequired();
        modelBuilder.Entity<Plane>().Property(p => p.LastFlightDate).IsRequired(false);
        modelBuilder.Entity<Plane>().Property(p => p.DeliveryDate).IsRequired(false);
        modelBuilder.Entity<Plane>().Property(p => p.SyncTime).IsRequired(false);
        modelBuilder.Entity<Plane>().Property(p => p.Capacity).IsRequired();
    }
  }
}  
```

6. Update DataContext file
* Open '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Infrastructure.Data\DataContext.cs' file and declare the DbSet associated to Plane:

```csharp
/// <summary>
/// Gets or sets the Plane DBSet.
/// </summary>
public DbSet<Plane> Planes { get; set; }
```
* On 'OnModelCreating' method add the 'PlaneModelBuilder':

```csharp
PlaneModelBuilder.CreateModel(modelBuilder);
```

7. Update the DataBase
* Launch the Package Manager Console (Tools > Nuget Package Manager > Package Manager Console).
* Be sure to have the project **MyCompany.MyFirstProject.Infrastructure.Data** selected as the Default Project in the console and the project **MyCompany.MyFirstProject.Presentation.Api** as the Startup Project of your solution
* Run first command:    
```ps
Add-Migration 'new_feature_Plane' -Context DataContext 
```
* Verify new file *'xxx_new_feature_Plane.cs'* is created on '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Infrastructure.Data\Migrations' folder, and file is not empty.
* Update the database when running this command: 
```ps
Update-DataBase -Context DataContext
```
* Verify 'Planes' table is created in the database.

8. Automatically CRUD generation   
We will use the BIAToolkit to finalize 'Plane' CRUD generation (back-end + front-end).  
* Start the BIAToolKit and go on "Modify existing project" tab*
* Set the projects parent path and choose your project
* Go to tab "3 - CRUD Generator"
* Choose Dto file: *PlaneDto.cs*
* Check "WebApi" and "Front" for Generation
* Check "CRUD" for Generation Type
* Verify "Entity name (singular)" value: *Plane*
* Set "Entity name (plural)" value: *Planes*
* Choose "Display item": *Msn*

![FirstCRUD_CRUDGenerator_Set](../../Images/GettingStarted/FirstCRUD_CRUDGenerator_Set.PNG)

* Click on generate button

9. Finalize DotNet generation
* Return to Visual Studio 2022 on the solution '...\MyFirstProject\DotNet\MyFirstProject.sln'.
* Rebuild solution
* Project will be run, launch IISExpress to verify it. 

10.    Finalize Angular generation
* Run VS code and open the folder 'C:\Sources\Test\MyFirstProject\Angular'
* Launch command on terminal 
```ps
npm start
```
* Errors can occurred like *'OptionDto' is declared but its value is never read.*, 
  * go to the file 'src/app/features/planes/model/plane.ts' 
  * delete *imports* in errors
* Open 'src/app/shared/navigation.ts' file and update path value to *'/planes'* for block with "labelKey" value is *'app.planes'* 
(see 'src/app/app-routing.module.ts' file to get the corresponding path)
* Open web navigator on address: *http://localhost:4200/* to display front page
* Click on *"APP.PLANES"* tab to display 'Planes' page.

11.    Add traduction
* Open 'src/assets/i18n/app/en.json' and add:
```json
  "app": {
    ...
    "planes": "Planes",
  },
  "plane": {
    "add": "Add plane",
    "capacity": "Capacity",
    "connectingAirports": "Connecting Airports",
    "deliveryDate": "Delivery Date",
    "edit": "Edit plane",
    "engines": "Engines",
    "isActive": "Active",
    "lastFlightDate": "Last flight date",
    "listOf": "List of planes",
    "msn": "Msn",
    "site": "Airline",
    "syncTime": "Synchronization time"
  },
```  
* Open 'src/assets/i18n/app/fr.json' and add:
```json
  "app": {
    ...
    "planes": "Avions",
  },
  "plane": {
    "add": "Ajouter avion",
    "capacity": "Capacité",
    "connectingAirports": "Aéroports de connection",
    "deliveryDate": "Date de livraison",
    "edit": "Modifier avion",
    "engines": "Moteurs",
    "isActive": "Actif",
    "lastFlightDate": "Date du dernier vol",
    "listOf": "Liste des avions",
    "msn": "Msn",
    "site": "Compagnie aérienne",
    "syncTime": "Heure de synchronisation"
  },
```
* Open 'src/assets/i18n/app/es.json' and add:
```json
  "app": {
    ...
    "planes": "Planos",
  },
  "plane": {
    "add": "Añadir plano",
    "capacity": "Capacidad",
    "connectingAirports": "Aeropuertos de conexión",
    "deliveryDate": "Fecha de entrega",
    "edit": "Editar plano",
    "engines": "motors",
    "isActive": "Activo",
    "lastFlightDate": "Última fecha de vuelo",
    "listOf": "Lista de planos",
    "msn": "Msn",
    "site": "Aerolínea",
    "syncTime": "Tiempo de sincronización"
  },
```  
* Open web navigator on adress: *http://localhost:4200/* to display front page
* Verify 'Plane' page have the good name (name put on previous file).
* Open 'Plane' page and verify labels have been replaced too.