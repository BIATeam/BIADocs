---
sidebar_position: 1
---

# Create your first Option
We will create the feature 'PlaneType'.

## Create the Entity
* Open with Visual Studio 2022 the solution '...\MyFirstProject\DotNet\MyFirstProject.sln'.
* Create the entity 'PlaneType':
* In '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain\PlaneModule\Aggregate' folder, create empty class 'PlaneType.cs' and add: 

```csharp
namespace MyCompany.MyFirstProject.Domain.Plane.Entities
{
    using System;
    using BIA.Net.Core.Domain;

    /// <summary>
    /// The plane entity.
    /// </summary>
    public class PlaneType : VersionedTable, IEntity<int>
    {
        /// <summary>
        /// Gets or sets the id.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Gets or sets the Manufacturer's Serial Number.
        /// </summary>
        public string Title { get; set; }

        /// <summary>
        /// Gets or sets the first flight date.
        /// </summary>
        public DateTime? CertificationDate { get; set; }
    }
}
```
## Update Data
### Create the ModelBuilder
* In '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Infrastructure.Data\ModelBuilders', open class 'PlaneModelBuilder.cs' and add:  

```csharp
public static void CreateModel(ModelBuilder modelBuilder)
{
  ...
    CreatePlaneTypeModel(modelBuilder);
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
```

### Update DataContext file
* Open '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Infrastructure.Data\DataContext.cs' file and declare the DbSet associated to PlaneType:

```csharp
/// <summary>
/// Gets or sets the Plane DBSet.
/// </summary>
public DbSet<PlaneType> PlanesTypes { get; set; }
```

### Update the DataBase
* Launch the Package Manager Console (Tools > Nuget Package Manager > Package Manager Console).
* Be sure to have the project **MyCompany.MyFirstProject.Infrastructure.Data** selected as the Default Project in the console and the project **MyCompany.MyFirstProject.Presentation.Api** as the Startup Project of your solution
* Run first command:    
```ps
Add-Migration 'new_feature_PlaneType' -Context DataContext 
```
* Verify new file *'xxx_new_feature_PlaneType.cs'* is created on '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Infrastructure.Data\Migrations' folder, and file is not empty.
* Update the database when running this command: 
```ps
Update-DataBase -Context DataContext
```
* Verify 'PlanesTypes' table is created in the database.

## Create the Option
### Using BIAToolKit
* Start the BIAToolKit and go on "Modify existing project" tab*
* Set the projects parent path and choose your project
* Go to tab "1 - Option Generator"
* Choose Entity: *PlaneType.cs*
* Fill the plural name: *PlaneTypes*
* Choose the display item: *Title*
* Set the Domain: *Plane*

![FirstOPTION_Set](../../Images/GettingStarted/FirstOPTION_Set.png)

* Click on generate button
### Finalize DotNet generation
* Return to Visual Studio 2022 on the solution '...\MyFirstProject\DotNet\MyFirstProject.sln'.
* Rebuild solution
* Project will be run, launch IISExpress to verify it. 
  
### Finalize Angular generation
* Run VS code and open the folder 'C:\Sources\Test\MyFirstProject\Angular'
* Launch command on terminal 
```ps
npm start
```