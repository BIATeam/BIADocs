---
layout: default
title: Create your first project
parent: Try it
grand_parent: Getting Started
nav_order: 20
---

# Build your first project

1. Create a project "MyFirstProject" with company name "MyCompany" using the BIAToolKit in folder "C:\Sources\Test". [Step desribe here](../../30-DeveloperGuide/50-BIAToolKit/20-CreateProject.md).
   ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-1-BIATollKit.PNG)

2. Open the folder "C:\Sources\Test\MyFirstProject"
   ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-2-Files.PNG)

3. Open with Visual Studio 2022 the solution "C:\Sources\Test\MyFirstProject\DotNet\MyFirstProject.sln"
   
4. In project MyCompany.MyFirstProject.DeployDB remane files 
   1. appsettings.Example_Development.json => appsettings.Development.json

5. In project MyCompany.MyFirstProject.Presentation.Api remane files 
   1. appsettings.Example_Development.json => appsettings.Development.json
   2. bianetconfig.Example_Development.json => bianetconfig.Development.json
   3. in bianetconfig.Development.json enter the short name and long name of your domaine in LdapDomains section : Replace DOMAIN_BIA_1 by the short name and the-user-domain1-name.bia by the long name.

6. In project MyCompany.MyFirstProject.WorkerService remane files 
   1. appsettings.Example_Development.json => appsettings.Development.json
   2. bianetconfig.Example_Development.json => bianetconfig.Development.json
   
7. Open Sql Server Management Studio and create a database named "MyFirstProject"
   ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-3-Database.PNG)

8. Launch the Package Manager Console in VS 2022 (Tools > Nuget Package Manager > Package Manager Console).

9. Be sure to have the project **MyCompany.MyFirstProject.Infrastructure.Data** selected as the Default Project in the console and the project **MyCompany.MyFirstProject..Presentation.Api** as the Startup Project of your solution.

10. In the package manager console, run the **Add-Migration** command to initialize the migrations for the database project. `Add-Migration Init -Context "DataContext"`

11. Set the project "MyCompany.MyFirstProject.DeployDB" as Sartup Project and run  it. It will create the tables in your databse :
    ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-4-Tables.PNG)

12. Set the project "MyCompany.MyFirstProject.DeployDB" as Sartup Project and run it.

13 The swagger page will be open. Click on "BIA login" at bottom right.

14 The button will be green.
    ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-5-Swagger.PNG)

15. If the button is red it is probably an error in bianetconfig.Example_Development.json? You can debug the function LoginOnTeamsAsync in 02 - Application\MyCompany.MyFirstProject.Application\User\AuthAppService.cs to understand the problem.

16. Run VS code and open the folder "C:\Sources\Test\MyFirstProject"
    
17. Open a new terminal and enter the commande:
    ```ps
    npm install
    npm start
    ```
![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-6-VSCode.PNG)

18. open a browser at adress http://localhost:4200/ (IIS express in Visual sudio should be always running)
    ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-7-Application.PNG)