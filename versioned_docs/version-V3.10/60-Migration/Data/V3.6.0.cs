using System;
using Microsoft.EntityFrameworkCore.Migrations;

namespace TheBIADevCompany.BIATemplate.Infrastructure.Data.Migrations
{
    public partial class V360 : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Members_Sites_SiteId",
                table: "Members");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Sites_SiteId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_NotificationTranslation_Languages_LanguageId",
                table: "NotificationTranslation");

            migrationBuilder.DropForeignKey(
                name: "FK_NotificationTranslation_Notifications_NotificationId",
                table: "NotificationTranslation");

        // moved after Notification Role seed
            //migrationBuilder.DropTable(
            //    name: "NotificationPermission");

            //migrationBuilder.DropTable(
            //    name: "PermissionRole");

            //migrationBuilder.DropTable(
            //    name: "PermissionTranslation");

        // moved after ViewTeam seed
            //migrationBuilder.DropTable(
            //    name: "ViewSite");

        // moved after Notification Role seed
            //migrationBuilder.DropTable(
            //    name: "Permission");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_SiteId",
                table: "Notifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_NotificationTranslation",
                table: "NotificationTranslation");

        // moved after team seed
            //migrationBuilder.DropColumn(
            //    name: "Title",
            //    table: "Sites");

        // moved after Notification Role seed
            //migrationBuilder.DropColumn(
            //    name: "SiteId",
            //    table: "Notifications");

            migrationBuilder.RenameTable(
                name: "NotificationTranslation",
                newName: "NotificationTranslations");

            migrationBuilder.RenameColumn(
                name: "SiteId",
                table: "Members",
                newName: "TeamId");

            migrationBuilder.RenameIndex(
                name: "IX_Members_SiteId_UserId",
                table: "Members",
                newName: "IX_Members_TeamId_UserId");

            migrationBuilder.RenameIndex(
                name: "IX_NotificationTranslation_NotificationId_LanguageId",
                table: "NotificationTranslations",
                newName: "IX_NotificationTranslations_NotificationId_LanguageId");

            migrationBuilder.RenameIndex(
                name: "IX_NotificationTranslation_LanguageId",
                table: "NotificationTranslations",
                newName: "IX_NotificationTranslations_LanguageId");

        // remove manually
            //migrationBuilder.AlterColumn<int>(
            //    name: "Id",
            //    table: "Sites",
            //    type: "int",
            //    nullable: false,
            //    oldClrType: typeof(int),
            //    oldType: "int")
            //    .OldAnnotation("SqlServer:Identity", "1, 1");
        // end remove manually

        // added manually

            migrationBuilder.DropForeignKey(
                name: "FK_ViewSite_Sites_SiteId",
                table: "ViewSite");

    // TODO Add the drop to other foreign key on site ID exemple :
            //migrationBuilder.DropForeignKey(
            //    name: "FK_Planes_Sites_SiteId",
            //    table: "Planes");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Sites",
                table: "Sites");

            migrationBuilder.CreateTable(
                name: "TmpSites",
                columns: table => new
                {
                    Id = table.Column<int>(nullable: false),
                    Title = table.Column<string>(maxLength: 256, nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                }
                ,
                constraints: table =>
                {
                    table.PrimaryKey("PK_Sites", x => x.Id);
                }
                );


            migrationBuilder.Sql(@"
                INSERT INTO[dbo].[TmpSites] (Id, Title) SELECT Id, Title FROM[dbo].[Sites]
                DROP TABLE [dbo].[Sites]
                EXECUTE sp_rename N'TmpSites', N'Sites'
            ");

    // TODO Add the creation to other foreign key exemple :
            //migrationBuilder.AddForeignKey(
            //    name: "FK_Planes_Sites_SiteId",
            //    table: "Planes",
            //    column: "SiteId",
            //    principalTable: "Sites",
            //    principalColumn: "Id",
            //    onDelete: ReferentialAction.Cascade);

        // end added manually

            migrationBuilder.AddPrimaryKey(
                name: "PK_NotificationTranslations",
                table: "NotificationTranslations",
                column: "Id");

            migrationBuilder.CreateTable(
                name: "AuditLogs",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Table = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    PrimaryKey = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true),
                    AuditDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    AuditAction = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AuditChanges = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AuditUserLogin = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "TeamTypes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TeamTypes", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserRoles",
                columns: table => new
                {
                    RolesId = table.Column<int>(type: "int", nullable: false),
                    UsersId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserRoles", x => new { x.RolesId, x.UsersId });
                    table.ForeignKey(
                        name: "FK_UserRoles_Roles_RolesId",
                        column: x => x.RolesId,
                        principalTable: "Roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserRoles_Users_UsersId",
                        column: x => x.UsersId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UsersAudit",
                columns: table => new
                {
                    AuditId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Id = table.Column<int>(type: "int", nullable: false),
                    FirstName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    LastName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Login = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Domain = table.Column<string>(type: "nvarchar(max)", nullable: false, defaultValue: "--"),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true),
                    AuditDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    AuditAction = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AuditChanges = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AuditUserLogin = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UsersAudit", x => x.AuditId);
                });

            migrationBuilder.CreateTable(
                name: "RoleTeamTypes",
                columns: table => new
                {
                    RolesId = table.Column<int>(type: "int", nullable: false),
                    TeamTypesId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RoleTeamTypes", x => new { x.RolesId, x.TeamTypesId });
                    table.ForeignKey(
                        name: "FK_RoleTeamTypes_Roles_RolesId",
                        column: x => x.RolesId,
                        principalTable: "Roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_RoleTeamTypes_TeamTypes_TeamTypesId",
                        column: x => x.TeamTypesId,
                        principalTable: "TeamTypes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Teams",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Title = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    TeamTypeId = table.Column<int>(type: "int", nullable: false, defaultValue: 2),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Teams", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Teams_TeamTypes_TeamTypeId",
                        column: x => x.TeamTypeId,
                        principalTable: "TeamTypes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "NotificationTeam",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    NotificationId = table.Column<int>(type: "int", nullable: false),
                    TeamId = table.Column<int>(type: "int", nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationTeam", x => x.Id);
                    table.ForeignKey(
                        name: "FK_NotificationTeam_Notifications_NotificationId",
                        column: x => x.NotificationId,
                        principalTable: "Notifications",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_NotificationTeam_Teams_TeamId",
                        column: x => x.TeamId,
                        principalTable: "Teams",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "ViewTeam",
                columns: table => new
                {
                    TeamId = table.Column<int>(type: "int", nullable: false),
                    ViewId = table.Column<int>(type: "int", nullable: false),
                    IsDefault = table.Column<bool>(type: "bit", nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ViewTeam", x => new { x.TeamId, x.ViewId });
                    table.ForeignKey(
                        name: "FK_ViewTeam_Teams_TeamId",
                        column: x => x.TeamId,
                        principalTable: "Teams",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ViewTeam_Views_ViewId",
                        column: x => x.ViewId,
                        principalTable: "Views",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

        // added manually
            
            migrationBuilder.Sql(@"
                INSERT INTO[dbo].[ViewTeam] (TeamId, ViewId, IsDefault) SELECT SiteId, ViewId, IsDefault FROM[dbo].[ViewSite]
            ");

            migrationBuilder.DropTable(
                name: "ViewSite");

        // end added manually

            migrationBuilder.CreateTable(
                name: "NotificationTeamRole",
                columns: table => new
                {
                    NotificationTeamId = table.Column<int>(type: "int", nullable: false),
                    RoleId = table.Column<int>(type: "int", nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationTeamRole", x => new { x.NotificationTeamId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_NotificationTeamRole_NotificationTeam_NotificationTeamId",
                        column: x => x.NotificationTeamId,
                        principalTable: "NotificationTeam",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_NotificationTeamRole_Roles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "Roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Roles",
                columns: new[] { "Id", "Code", "Label" },
                values: new object[,]
                {
                    { 10001, "Admin", "Administrator" },
                    { 10002, "Back_Admin", "Background task administrator" },
                    { 10003, "Back_Read_Only", "Visualization of background tasks" }
                });

            migrationBuilder.InsertData(
                table: "TeamTypes",
                columns: new[] { "Id", "Name" },
                values: new object[,]
                {
                    { 1, "Root" },
                    { 2, "Site" }
                });

        // added manually after InsertData("TeamTypes"
        
            migrationBuilder.Sql(@"
                SET IDENTITY_INSERT [dbo].[Teams] ON
                INSERT INTO[dbo].[Teams] (Id, TeamTypeId, Title) SELECT Id, '2', Title FROM[dbo].[Sites]
                SET IDENTITY_INSERT [dbo].[Teams] OFF
            ");
            
            migrationBuilder.Sql(@"
                INSERT INTO[dbo].[NotificationTeam] (NotificationId, TeamId) SELECT Id, SiteId FROM[dbo].[Notifications]
            ");

            // Works only if PermissionId correspond to RoleId
            migrationBuilder.Sql(@"
                INSERT INTO[dbo].[NotificationTeamRole] (NotificationTeamId, RoleId) 
                SELECT NT.Id, NP.PermissionId 
                FROM [dbo].[Notifications] AS N 
                INNER JOIN [dbo].[NotificationTeam] AS NT ON N.Id = NT.NotificationId
                INNER JOIN [dbo].[NotificationPermission] AS NP ON N.Id = NP.NotificationId
            ");

            migrationBuilder.DropColumn(
                name: "SiteId",
                table: "Notifications");

            migrationBuilder.DropTable(
                name: "NotificationPermission");

            migrationBuilder.DropTable(
                name: "PermissionRole");

            migrationBuilder.DropTable(
                name: "PermissionTranslation");

            migrationBuilder.DropTable(
                name: "Permission");

            migrationBuilder.DropColumn(
                name: "Title",
                table: "Sites");
        // end added manually

            migrationBuilder.InsertData(
                table: "RoleTeamTypes",
                columns: new[] { "RolesId", "TeamTypesId" },
                values: new object[,]
                {
                    { 10001, 1 },
                    { 10002, 1 },
                    { 10003, 1 },
                    { 1, 2 }
                });

            migrationBuilder.InsertData(
                table: "RoleTranslations",
                columns: new[] { "Id", "Label", "LanguageId", "RoleId" },
                values: new object[,]
                {
                    { 1000101, "Administrateur", 2, 10001 },
                    { 1000102, "Administrador", 3, 10001 },
                    { 1000103, "Administrator", 4, 10001 },
                    { 1000201, "Administrateur des tâches en arrière-plan", 2, 10002 },
                    { 1000202, "Administrador de tareas en segundo plano", 3, 10002 },
                    { 1000203, "Administrator für Hintergrundaufgaben", 4, 10002 },
                    { 1000301, "Visualisation des tâches en arrière-plan", 2, 10003 },
                    { 1000302, "Visualización de tareas en segundo plano", 3, 10003 },
                    { 1000303, "Visualisierung von Hintergrundaufgaben", 4, 10003 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_NotificationTeam_NotificationId",
                table: "NotificationTeam",
                column: "NotificationId");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationTeam_TeamId",
                table: "NotificationTeam",
                column: "TeamId");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationTeamRole_RoleId",
                table: "NotificationTeamRole",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_RoleTeamTypes_TeamTypesId",
                table: "RoleTeamTypes",
                column: "TeamTypesId");

            migrationBuilder.CreateIndex(
                name: "IX_Teams_TeamTypeId",
                table: "Teams",
                column: "TeamTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_UserRoles_UsersId",
                table: "UserRoles",
                column: "UsersId");

            migrationBuilder.CreateIndex(
                name: "IX_ViewTeam_ViewId",
                table: "ViewTeam",
                column: "ViewId");

            migrationBuilder.AddForeignKey(
                name: "FK_Members_Teams_TeamId",
                table: "Members",
                column: "TeamId",
                principalTable: "Teams",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_NotificationTranslations_Languages_LanguageId",
                table: "NotificationTranslations",
                column: "LanguageId",
                principalTable: "Languages",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_NotificationTranslations_Notifications_NotificationId",
                table: "NotificationTranslations",
                column: "NotificationId",
                principalTable: "Notifications",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Sites_Teams_Id",
                table: "Sites",
                column: "Id",
                principalTable: "Teams",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Members_Teams_TeamId",
                table: "Members");

            migrationBuilder.DropForeignKey(
                name: "FK_NotificationTranslations_Languages_LanguageId",
                table: "NotificationTranslations");

            migrationBuilder.DropForeignKey(
                name: "FK_NotificationTranslations_Notifications_NotificationId",
                table: "NotificationTranslations");

            migrationBuilder.DropForeignKey(
                name: "FK_Sites_Teams_Id",
                table: "Sites");

            migrationBuilder.DropTable(
                name: "AuditLogs");

            migrationBuilder.DropTable(
                name: "NotificationTeamRole");

            migrationBuilder.DropTable(
                name: "RoleTeamTypes");

            migrationBuilder.DropTable(
                name: "UserRoles");

            migrationBuilder.DropTable(
                name: "UsersAudit");

            migrationBuilder.DropTable(
                name: "ViewTeam");

            migrationBuilder.DropTable(
                name: "NotificationTeam");

            migrationBuilder.DropTable(
                name: "Teams");

            migrationBuilder.DropTable(
                name: "TeamTypes");

            migrationBuilder.DropPrimaryKey(
                name: "PK_NotificationTranslations",
                table: "NotificationTranslations");

            migrationBuilder.DeleteData(
                table: "RoleTranslations",
                keyColumn: "Id",
                keyValue: 1000101);

            migrationBuilder.DeleteData(
                table: "RoleTranslations",
                keyColumn: "Id",
                keyValue: 1000102);

            migrationBuilder.DeleteData(
                table: "RoleTranslations",
                keyColumn: "Id",
                keyValue: 1000103);

            migrationBuilder.DeleteData(
                table: "RoleTranslations",
                keyColumn: "Id",
                keyValue: 1000201);

            migrationBuilder.DeleteData(
                table: "RoleTranslations",
                keyColumn: "Id",
                keyValue: 1000202);

            migrationBuilder.DeleteData(
                table: "RoleTranslations",
                keyColumn: "Id",
                keyValue: 1000203);

            migrationBuilder.DeleteData(
                table: "RoleTranslations",
                keyColumn: "Id",
                keyValue: 1000301);

            migrationBuilder.DeleteData(
                table: "RoleTranslations",
                keyColumn: "Id",
                keyValue: 1000302);

            migrationBuilder.DeleteData(
                table: "RoleTranslations",
                keyColumn: "Id",
                keyValue: 1000303);

            migrationBuilder.DeleteData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 10001);

            migrationBuilder.DeleteData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 10002);

            migrationBuilder.DeleteData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 10003);

            migrationBuilder.RenameTable(
                name: "NotificationTranslations",
                newName: "NotificationTranslation");

            migrationBuilder.RenameColumn(
                name: "TeamId",
                table: "Members",
                newName: "SiteId");

            migrationBuilder.RenameIndex(
                name: "IX_Members_TeamId_UserId",
                table: "Members",
                newName: "IX_Members_SiteId_UserId");

            migrationBuilder.RenameIndex(
                name: "IX_NotificationTranslations_NotificationId_LanguageId",
                table: "NotificationTranslation",
                newName: "IX_NotificationTranslation_NotificationId_LanguageId");

            migrationBuilder.RenameIndex(
                name: "IX_NotificationTranslations_LanguageId",
                table: "NotificationTranslation",
                newName: "IX_NotificationTranslation_LanguageId");

            migrationBuilder.AlterColumn<int>(
                name: "Id",
                table: "Sites",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int")
                .Annotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "Sites",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "SiteId",
                table: "Notifications",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddPrimaryKey(
                name: "PK_NotificationTranslation",
                table: "NotificationTranslation",
                column: "Id");

            migrationBuilder.CreateTable(
                name: "Permission",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Label = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Permission", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ViewSite",
                columns: table => new
                {
                    SiteId = table.Column<int>(type: "int", nullable: false),
                    ViewId = table.Column<int>(type: "int", nullable: false),
                    IsDefault = table.Column<bool>(type: "bit", nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ViewSite", x => new { x.SiteId, x.ViewId });
                    table.ForeignKey(
                        name: "FK_ViewSite_Sites_SiteId",
                        column: x => x.SiteId,
                        principalTable: "Sites",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ViewSite_Views_ViewId",
                        column: x => x.ViewId,
                        principalTable: "Views",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "NotificationPermission",
                columns: table => new
                {
                    PermissionId = table.Column<int>(type: "int", nullable: false),
                    NotificationId = table.Column<int>(type: "int", nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationPermission", x => new { x.PermissionId, x.NotificationId });
                    table.ForeignKey(
                        name: "FK_NotificationPermission_Notifications_NotificationId",
                        column: x => x.NotificationId,
                        principalTable: "Notifications",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_NotificationPermission_Permission_PermissionId",
                        column: x => x.PermissionId,
                        principalTable: "Permission",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "PermissionRole",
                columns: table => new
                {
                    PermissionId = table.Column<int>(type: "int", nullable: false),
                    RoleId = table.Column<int>(type: "int", nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PermissionRole", x => new { x.PermissionId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_PermissionRole_Permission_PermissionId",
                        column: x => x.PermissionId,
                        principalTable: "Permission",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PermissionRole_Roles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "Roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PermissionTranslation",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Label = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    LanguageId = table.Column<int>(type: "int", nullable: false),
                    PermissionId = table.Column<int>(type: "int", nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PermissionTranslation", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PermissionTranslation_Languages_LanguageId",
                        column: x => x.LanguageId,
                        principalTable: "Languages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PermissionTranslation_Permission_PermissionId",
                        column: x => x.PermissionId,
                        principalTable: "Permission",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Permission",
                columns: new[] { "Id", "Code", "Label" },
                values: new object[] { 1, "Site_Admin", "Site administrator" });

            migrationBuilder.InsertData(
                table: "PermissionRole",
                columns: new[] { "PermissionId", "RoleId" },
                values: new object[] { 1, 1 });

            migrationBuilder.InsertData(
                table: "PermissionTranslation",
                columns: new[] { "Id", "Label", "LanguageId", "PermissionId" },
                values: new object[,]
                {
                    { 101, "Administrateur du site", 2, 1 },
                    { 102, "Administrador del sitio", 3, 1 },
                    { 103, "Seitenadministrator", 4, 1 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_SiteId",
                table: "Notifications",
                column: "SiteId");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationPermission_NotificationId",
                table: "NotificationPermission",
                column: "NotificationId");

            migrationBuilder.CreateIndex(
                name: "IX_PermissionRole_RoleId",
                table: "PermissionRole",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_PermissionTranslation_LanguageId",
                table: "PermissionTranslation",
                column: "LanguageId");

            migrationBuilder.CreateIndex(
                name: "IX_PermissionTranslation_PermissionId_LanguageId",
                table: "PermissionTranslation",
                columns: new[] { "PermissionId", "LanguageId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ViewSite_ViewId",
                table: "ViewSite",
                column: "ViewId");

            migrationBuilder.AddForeignKey(
                name: "FK_Members_Sites_SiteId",
                table: "Members",
                column: "SiteId",
                principalTable: "Sites",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Sites_SiteId",
                table: "Notifications",
                column: "SiteId",
                principalTable: "Sites",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_NotificationTranslation_Languages_LanguageId",
                table: "NotificationTranslation",
                column: "LanguageId",
                principalTable: "Languages",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_NotificationTranslation_Notifications_NotificationId",
                table: "NotificationTranslation",
                column: "NotificationId",
                principalTable: "Notifications",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
