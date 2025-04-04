---
sidebar_position: 1
---

# Create your first Relation
We will create a relation between CRUD 'Plane' and option 'PlaneType' (previously created).

1. Open with Visual Studio 2022 the solution '...\MyFirstProject\DotNet\MyFirstProject.sln'.

2. Open the entity 'Plane':
* In '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain\PlaneModule\Aggregate' open class 'Plane.cs' and add 'PlaneType' declaration: 
  
```csharp
/// <summary>
/// Gets or sets the  plane type.
/// </summary>
public virtual PlaneType PlaneType { get; set; }

/// <summary>
/// Gets or sets the plane type id.
/// </summary>
public int? PlaneTypeId { get; set; }
```

3. Update the DTO 'PlaneDto':
* In '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain.Dto\Pane' open class 'PlaneDto.cs' and add 'PlaneType' declaration:  
  
```csharp
/// <summary>
/// Gets or sets the  plane type title.
/// </summary>
[BiaDtoField(ItemType = "PlaneType")]
public OptionDto PlaneType { get; set; }
```

4. Update the Mapper 'PlaneMapper':
* In '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Domain\PlaneModule\Aggregate' folder, open class 'PlaneMapper' and add:   
 
```csharp
public override ExpressionCollection<Plane> ExpressionCollection
{
    ...
    { HeaderName.PlaneType, plane => plane.PlaneType != null ? plane.PlaneType.Title : null },
}

public override void DtoToEntity(PlaneDto dto, Plane entity)
{
    ...
    // Mapping relationship 0..1-* : PlaneType
    entity.PlaneTypeId = dto.PlaneType?.Id;
}

public override Expression<Func<Plane, PlaneDto>> EntityToDto()
{
    ...
    // Mapping relationship 0..1-* : PlaneType
    PlaneType = entity.PlaneType != null ? new OptionDto
    {
        Id = entity.PlaneType.Id,
        Display = entity.PlaneType.Title,
    }
    : null,
}

public override Func<PlaneDto, object[]> DtoToRecord(List<string> headerNames = null)
{
    ...
    if (string.Equals(headerName, HeaderName.PlaneType, StringComparison.OrdinalIgnoreCase))
    {
        records.Add(CSVString(x.PlaneType?.Display));
    }
}

public struct HeaderName
{
    ...
    /// <summary>
    /// Header Name PlaneType.
    /// </summary>
    public const string PlaneType = "planeType";
}
```

5. Update the ModelBuilder
* In '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Infrastructure.Data\ModelBuilders', open class 'PlaneModelBuilder.cs' and add 'PlaneType' relationship: 
 
```csharp
/// <summary>
/// Create the model for planes.
/// </summary>
/// <param name="modelBuilder">The model builder.</param>
private static void CreatePlaneModel(ModelBuilder modelBuilder)
{
    ...
    modelBuilder.Entity<Plane>().Property(p => p.PlaneTypeId).IsRequired(false); // relationship 0..1-*
    modelBuilder.Entity<Plane>().HasOne(x => x.PlaneType).WithMany().HasForeignKey(x => x.PlaneTypeId);
}
```

6. Update the DataBase
* Launch the Package Manager Console (Tools > Nuget Package Manager > Package Manager Console).
* Be sure to have the project **MyCompany.MyFirstProject.Infrastructure.Data** selected as the Default Project in the console and the project **MyCompany.MyFirstProject.Presentation.Api** as the Startup Project of your solution
* Run first command:    
```ps
Add-Migration 'update_feature_Plane' -Context DataContext 
```
* Verify new file *'xxx_update_feature_Plane.cs'* is created on '...\MyFirstProject\DotNet\MyCompany.MyFirstProject.Infrastructure.Data\Migrations' folder, and file is not empty.
* Update the database when running this command: 
```ps
Update-DataBase -Context DataContext
```
* Verify 'Planes' table is updated in the database (column *'PlaneTypeId'* was added).
  
7. Automatically Update CRUD  
* Start the BIAToolKit and go on "Modify existing project" tab*
* Choose:
  * Projects parent path to "C:\Sources\Test"
  * Project folder to *MyFirstProject*
* Open "Add CRUD" tab
* Generation:
  * Choose Dto file: *PlaneDto.cs*
  * Information message appear: "Generation was already done for this Dto file"
  * Verify "WebApi" and "Front" Generation are checked
  * Verify only "CRUD" Generation Type is checked
  * Verify "Entity name (singular)" value is *Plane*
  * Verify "Entity name (plural)" value is *Planes*
  * Verify "Display item"  value is *Msn*
  * On option item list, check "PlaneType" value
  * Click on "Generate" button

8. Check DotNet generation
* Return to Visual Studio 2022 on the solution '...\MyFirstProject\DotNet\MyFirstProject.sln'.
* Rebuild solution
* Project will be run, launch IISExpress to verify it. 

9. Check Angular generation
* Run VS code and open the folder 'C:\Sources\Test\MyFirstProject\Angular'
* Launch command on terminal 
```ps
npm start
```
* Open 'src/app/shared/navigation.ts' file and update path value to *'/planes'* for block with "labelKey" value is *'app.planes'*   
(see 'src/app/app-routing.module.ts' file to get the corresponding path)
* Open web navigator on address: *http://localhost:4200/* to display front page
* Click on *"PLANES"* tab to display 'Planes' page.

10. Add traduction
* Open 'src/assets/i18n/app/en.json' and add:
```json
  "plane": {
    ...
    "planeType": "Plane Type",
  },
```  
* Open 'src/assets/i18n/app/fr.json' and add:
```json
  "app": {
    ...
    "planes": "Avions",
  },
  "plane": {
    ...
    "planeType": "Type d'avions",
  },
```
* Open 'src/assets/i18n/app/es.json' and add:
```json
  "app": {
    ...
    "planes": "Planos",
  },
  "plane": {
    ...
    "planeType": "Tipos de planos",
  },
```  
* Open web navigator on address: *http://localhost:4200/* to display front page
* Open 'Plane' page and verify label has been replaced.