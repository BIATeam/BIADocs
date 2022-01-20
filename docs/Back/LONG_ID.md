---
layout: default
title: Switch to long Id
parent: Back
nav_order: 3
---

# Switch to long Id
This document explains how to switch an entity id from int to long. It can be use similary to switch to GUID.   
<u>For this example, we have switch the id of the entity: <span style="background-color:#327f00">plane</span>.</u>


## Transform the entity
Use long in the inheritance IEntity and in the Id type
  ``` csharp
      public class Plane : VersionedTable, IEntity<long>
      {
          /// <summary>
          /// Gets or sets the id.
          /// </summary>
          public long Id { get; set; }
  ```

## Transform the dto 
Use long in the inheritance BaseDto
  ``` csharp
      public class PlaneDto : BaseDto<long>
  ```

## Transform the mapper 
Use long in the inheritance BaseMapper
  ``` csharp
      public class PlaneMapper : BaseMapper<PlaneDto, Plane, long>
  ```

## Transform the related entities
If the entity id is reference by other table change the type in related entities. 
  ``` csharp
    public class PlaneAirport : VersionedTable
    {
        /// <summary>
        /// Gets or sets the conformcertif.
        /// </summary>
        public Plane Plane { get; set; }

        /// <summary>
        /// Gets or sets the conformcertif id.
        /// </summary>
        public long PlaneId { get; set; }

        /// <summary>
        /// Gets or sets the site.
        /// </summary>
        public Airport Airport { get; set; }

        /// <summary>
        /// Gets or sets the site id.
        /// </summary>
        public int AirportId { get; set; }
    }
  ```
## Transform the service 
Use long as TKey type in the inheritance CrudAppServiceBase
  ``` csharp
    public class PlaneAppService : CrudAppServiceBase<PlaneDto, Plane, long, PagingFilterFormatDto, PlaneMapper>, IPlaneAppService
  ```

## Transform the service interface
Use long as TKey type in the inheritance ICrudAppServiceBase
  ``` csharp
    public interface IPlaneAppService : ICrudAppServiceBase<PlaneDto, Plane, long, PagingFilterFormatDto>
  ```

## Transform the controller
Use long ithe list of ids in Remove function
  ``` csharp
        public async Task<IActionResult> Remove([FromQuery] List<long> ids)
  ```

## Generate the migration
Add-Migration "<span style="background-color:#327f00">Plane</span>LongId" -Context "DataContext"

## Adapt the migration
Due to a known bu in ef5.0 you have to add manualy the remove of the PrimaryKey and ForeignKey on each element modified, and recreate them after change in Up and Down function.
  ``` csharp
    public partial class PlaneLongId : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Begin Manualy Added
            migrationBuilder.DropForeignKey(
                name: "FK_PlaneAirport_Planes_PlaneId",
                table: "PlaneAirport");
            migrationBuilder.DropPrimaryKey(
                name: "PK_Planes", 
                table: "Planes");
            migrationBuilder.DropPrimaryKey(
                name: "PK_PlaneAirport",
                table: "PlaneAirport");
            // End Manualy Added

            migrationBuilder.AlterColumn<long>(
                name: "Id",
                table: "Planes",
                type: "bigint",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int")
                .Annotation("SqlServer:Identity", "1, 1")
                .OldAnnotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AlterColumn<long>(
                name: "PlaneId",
                table: "PlaneAirport",
                type: "bigint",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int");

            // Begin Manualy Added
            migrationBuilder.AddPrimaryKey(
                name: "PK_Planes",
                table: "Planes",
                column: "Id");
            migrationBuilder.AddForeignKey(
                name: "FK_PlaneAirport_Planes_PlaneId",
                table: "PlaneAirport",
                column: "PlaneId",
                principalTable: "Planes",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
            migrationBuilder.AddPrimaryKey(
                name: "PK_PlaneAirport",
                table: "PlaneAirport",
                columns: new string[] {"PlaneId", "AirportId"});
            // End Manualy Added
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Begin Manualy Added
            migrationBuilder.DropForeignKey(
                name: "FK_PlaneAirport_Planes_PlaneId",
                table: "PlaneAirport");
            migrationBuilder.DropPrimaryKey(
                name: "PK_Planes",
                table: "Planes");
            migrationBuilder.DropPrimaryKey(
                name: "PK_PlaneAirport",
                table: "PlaneAirport");
            // End Manualy Added

            migrationBuilder.AlterColumn<int>(
                name: "Id",
                table: "Planes",
                type: "int",
                nullable: false,
                oldClrType: typeof(long),
                oldType: "bigint")
                .Annotation("SqlServer:Identity", "1, 1")
                .OldAnnotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AlterColumn<int>(
                name: "PlaneId",
                table: "PlaneAirport",
                type: "int",
                nullable: false,
                oldClrType: typeof(long),
                oldType: "bigint");

            // Begin Manualy Added
            migrationBuilder.AddPrimaryKey(
                name: "PK_Planes",
                table: "Planes",
                column: "Id");
            migrationBuilder.AddForeignKey(
                name: "FK_PlaneAirport_Planes_PlaneId",
                table: "PlaneAirport",
                column: "PlaneId",
                principalTable: "Planes",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
            migrationBuilder.AddPrimaryKey(
                name: "PK_PlaneAirport",
                table: "PlaneAirport",
                columns: new string[] { "PlaneId", "AirportId" });
            // End Manualy Added
        }
    }
  ```

## Migrate the base 
Update-Database -Context "DataContext"

