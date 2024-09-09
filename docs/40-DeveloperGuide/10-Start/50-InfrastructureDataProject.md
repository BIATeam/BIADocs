---
sidebar_position: 1
---
# Infrastructure data project

## Preparation of the Database

1. Create the database on your local instance
    - The name of the database should be the name of the project you can verify the connection string in the appsettings.json file and the declined files by environment
2. Rename and modify the appsetting file
    - appsettings.Example_Development.json => appsettings.Development.json
    - if needed rename the server localhost to your local server name
3. Launch the Package Manager Console in VS 2022 (Tools > Nuget Package Manager > Package Manager Console).
4. Be sure to have the project **[YourCompanyName].[YourProjectName].Infrastructure.Data** selected as the Default Project in the console and the project **[YourCompanyName].[YourProjectName].Presentation.Api** as the Startup Project of your solution.
5. (ONLY if no migration have been done = new project or never use) Run the **Add-Migration** command to initialize the migrations for the database project. `Add-Migration [nameOfYourMigration] -Context "DataContext"`
6. Run the **Update-Database** command to update you database schema (you can check if everything is fine in SQL Server Management Studio).  `Update-Database -Context "DataContext"`
7. (OPTIONALLY) Update the Roles section in the bianetconfig.json file and the declined files by environment to use the correct AD groups or the Fakes roles.
8. (OPTIONALLY) Update the version of the application. To do this, change the variable: **TheBIADevCompany.[ProjectName].Crosscutting.Common.Constants.Application.Version**.
