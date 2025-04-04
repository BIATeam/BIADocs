---
sidebar_position: 1
---

# Create your first Child
We will create in first the child feature 'Engines'.

## Prerequisites
### CRUD Parent creation
Follow steps from the section [Create your first CRUD](./30-CreateYourFirstCRUD.md) to create the parent's child.

We will assume that the parent is a Plane for this documentation.

### Create the DTO
1. Open with Visual Studio 2022 the solution **'...\MyFirstProject\DotNet\MyFirstProject.sln'**.
2. In **'...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain.Dto\Plane'**.
3. Create empty class **'EngineDto.cs'** and add following:
```csharp title="EngineDto.cs"
// <copyright file="EngineDto.cs" company="MyCompany">
// Copyright (c) MyCompany. All rights reserved.
// </copyright>

namespace MyCompany.MyFirstProject.Domain.Dto.Plane
{
    using BIA.Net.Core.Domain.Dto.CustomAttribute;

    /// <summary>
    /// The DTO used to represent an engine.
    /// </summary>
    public class EngineDto
    {
        /// <summary>
        /// Gets or sets the parent's plane id.
        /// </summary>
        [BiaDtoField(IsParent = true, Required = true)]
        public int PlaneId { get; set; }

        /// <summary>
        /// Get or sets the engine serial number.
        /// </summary>
        public string SN { get; set; }
    }
}
```

### Create the Model
1. In **'...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain\PlaneModule\Aggregate'**
2. Create empty class **'Engine.cs'** and add following:
```csharp title="Engine.cs"
// <copyright file="Engine.cs" company="MyCompany">
// Copyright (c) MyCompany. All rights reserved.
// </copyright>

namespace MyCompany.MyFirstProject.Domain.PlaneModule.Aggregate
{
    /// <summary>
    /// The engine entity.
    /// </summary>
    public class Engine : VersionedTable, IEntity<int>
    {
        /// <summary>
        /// Gets or sets the engine Id.
        /// </summary>
        public int Id { get; set; }

        /// <summary>
        /// Gets or sets the engine serial number.
        /// </summary>
        public string SN { get; set; }

        /// <summary>
        /// Gets or sets the plane Id.
        /// </summary>
        public int PlaneId { get; set; }

        /// <summary>
        /// Gets or sets the plane.
        /// </summary>
        public virtual Plane Plane { get; set; }
    }
}
```
3. In **Plane.cs**, add a new `ICollection<Engine>` to the model:
```csharp title="Plane.cs"
// <copyright file="Plane.cs" company="MyCompany">
// Copyright (c) MyCompany. All rights reserved.
// </copyright>

namespace MyCompany.MyFirstProject.Domain.PlaneModule.Aggregate
{
    public class Plane : VersionedTable, IEntity<int>
    {
        /// [...]

        /// <summary>
        /// Gets or sets the list of engines.
        /// </summary>
        public ICollection<Engine> Engines { get; set; }
    }
}
```

### Create the Mapper
1. Stay in **'...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain\PlaneModule\Aggregate'** folder.
2. Create empty class **'EngineMapper.cs'** and add following:
```csharp title="EngineMapper.cs"
// <copyright file="EngineMapper.cs" company="MyCompany">
// Copyright (c) MyCompany. All rights reserved.
// </copyright>

namespace MyCompany.MyFirstProject.Domain.CompanyModule.Aggregate
{
    using System;
    using System.Linq;
    using System.Linq.Expressions;
    using System.Security.Principal;
    using BIA.Net.Core.Domain.Authentication;
    using MyCompany.MyFirstProject.Crosscutting.Common.Enum;
    using MyCompany.MyFirstProject.Domain.Dto.Company;
    using MyCompany.MyFirstProject.Domain.UserModule.Aggregate;

    /// <summary>
    /// The mapper used for engine.
    /// </summary>
    public class EngineMapper : BaseMapper<EngineDto, Engine, int>
    {
        /// <inheritdoc cref="BaseMapper{TDto,TEntity}.ExpressionCollection"/>
        public override ExpressionCollection<Engine> ExpressionCollection
        {
            get
            {
                return new ExpressionCollection<Engine>
                {
                    { "id", engine => engine.Id },
                    { "sn", engine => engine.SN },
                };
            }
        }

        /// <inheritdoc cref="BaseMapper{TDto,TEntity}.DtoToEntity"/>
        public override void DtoToEntity(EngineDto dto, Engine entity)
        {
            entity ??= new Engine();

            entity.Id = dto.Id;
            entity.SN = dto.SN;
            entity.PlaneId = dto.PlaneId;
        }

        /// <inheritdoc cref="BaseMapper{TDto,TEntity}.EntityToDto"/>
        public override Expression<Func<Engine, EngineDto>> EntityToDto()
        {
            return entity => new EngineDto
            {
                Id = entity.Id,
                SN = entity.SN,
                PlaneId = entity.PlaneId,
            };
        }
    }
}
```

### Complete DataContext
1. Go in **'...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Infrastructure.Data'** folder.
2. Open **DataContext.cs** and add your new `DbSet<Engine>` :

```csharp title="DataContext.cs"
    public class DataContext : BiaDataContext
    {
        // Existing DbSet<T>

        /// <summary>
        /// Gets or sets the Engine DBSet.
        /// </summary>
        public DbSet<Engine> Engines { get; set; }
    }
```
3. In folder **ModelBuilders**, create class **EngineModelBuilder.cs** or use parent's model builder, and add :
```csharp title="EngineModelBuilder.cs"
namespace MyCompany.MyFirstProject.Infrastructure.Data.ModelBuilders
{
    using Microsoft.EntityFrameworkCore;
    using MyCompany.MyFirstProject.Domain.CompanyModule.Aggregate;

    /// <summary>
    /// Class used to update the model builder for Engine domain.
    /// </summary>
    public static class EngineModelBuilder
    {
        /// <summary>
        /// Create the model for projects.
        /// </summary>
        /// <param name="modelBuilder">The model builder.</param>
        public static void CreateModel(ModelBuilder modelBuilder)
        {
            CreateEngineModel(modelBuilder);
        }

        /// <summary>
        /// Create the model for engines.
        /// </summary>
        /// <param name="modelBuilder">The model builder.</param>
        private static void CreateEngineModel(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Engine>().HasOne(x => x.Plane).WithMany(x => x.Engines).HasForeignKey(x => x.PlaneId);
        }
    }
}
```
4. Back to **DataContext.cs**, ensure to have a call to your model builder's method `CreateModel` :
```csharp title="DataContext.cs"
    public class DataContext : BiaDataContext
    {
        /// <inheritdoc cref="DbContext.OnModelCreating"/>
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Existing model builders
            
            EngineModelBuilder.CreateModel(modelBuilder);
            this.OnEndModelCreating(modelBuilder);
        }
    }
```

### Update the database
1. Open a new Package Manager Console.
2. Set default project to **MyCompany.MyFirstProject.Infrastructure.Data**.
3. Run command `add-migration -context "DataContext" AddEngines`.
4. Verify the generated migration.
5. Run command `update-database -context "DataContext"`
6. Verify your database.

## Generate CRUD Child
### Using BIAToolKit
1. Launch the **BIAToolKit**, go to the tab **"Modify existing project"**.
2. Set your parent project path, then select your project folder.
3. Go to **"Add CRUD"** tab.
4. Fill the form as following : 
![BIAToolKitConfig](../../Images/BIAToolKit/CRUD-Child_Add.png)
    <ins>Explanations</ins> :
   - **Parent name (singular or plural)** : corresponding in the back-end to the class names and in the front-end to the feature name of the parent.
   - **Parent domain** : corresponding in the back-end only to the domain name where the parent is currently created.

    Based on this informations, the BIAToolKit will detect automatically the parent's folders to generate the new CRUD child. Make sure to fill the correct informations without misspelling.
1. Then, click on **Generate** button !

### Customize generated files
#### Front
##### model.ts
1. Go in **'src\app\features\planes\children\engines\model'** and open the **engine.ts** file.
2. Adapt the field configuration if needed.
3. Remove all unused imports from the generated file.
4. 
##### engine-item.component.ts
1. Go in **'src\app\features\planes\children\engines\views'** and open the **engine-item.component.ts** file.
2. Adapt the field of the item to display in the breadcrump.

### Complete traductions
1. Go in **'...\MyFirstProject\Angular\src\assets\i18n\app'**
2. Complete each available language traduction JSON file with the correct values : 
```json title="en.json"
"app": {
    //...
    "engines": "engines"
  },
  "engine": {
    "add": "Add engine",
    "edit": "Edit engine",
    "listOf": "List of engines",
    "plane": "Plane",
    "sn": "Serial Number",
  },
```

## Testing your CRUD Child
1. Run the DotNet solution.
2. Launch `npm start` in Angular folder.
3. Go to *http://localhost:4200/*
4. Navigate to the plane list.
5. Select one plane (create one if needed) and click on the button "Engines":
![CrudParentList](../../Images/BIAToolKit/CRUD-Child_Parent-List.png)
6. You should access to the engines list of the plane.
![CrudList](../../Images/BIAToolKit/CRUD-Child_List.png)