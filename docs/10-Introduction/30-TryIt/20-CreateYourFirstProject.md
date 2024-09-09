---
sidebar_position: 1
---

# Build your first project

1. Create a project "MyFirstProject" with company name "MyCompany" using the BIAToolKit in folder "C:\Sources\Test". [Step describe here](../../30-BIAToolKit/20-CreateProject.md). If you have company files used them to have correct settings.
  ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-1-BIATollKit.PNG)

1. Open the folder "C:\Sources\Test\MyFirstProject"   
   ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-2-Files.PNG)

2. Open with Visual Studio 2022 the solution "C:\Sources\Test\MyFirstProject\DotNet\MyFirstProject.sln"
   
3. ONLY If you have not company files containing configuration files
   1.  In project MyCompany.MyFirstProject.DeployDB rename files 
       1. appsettings.Example_Development.json => appsettings.Development.json

   2. In project MyCompany.MyFirstProject.Presentation.Api rename files 
      1. appsettings.Example_Development.json => appsettings.Development.json
      2. bianetconfig.Example_Development.json => bianetconfig.Development.json
      3. in bianetconfig.Development.json, in LdapDomains section enter the short name and long name of your domain : Replace DOMAIN_BIA_1 by the short name and the-user-domain1-name.bia by the long name.

   3. In project MyCompany.MyFirstProject.WorkerService rename files 
      1. appsettings.Example_Development.json => appsettings.Development.json
      2. bianetconfig.Example_Development.json => bianetconfig.Development.json
   
4. Open Sql Server Management Studio and create a database named "MyFirstProject"   
   ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-3-Database.PNG)

5. Launch the Package Manager Console in VS 2022 (Tools > Nuget Package Manager > Package Manager Console).

6.  Be sure to have the project **MyCompany.MyFirstProject.Infrastructure.Data** selected as the Default Project in the console and the project **MyCompany.MyFirstProject.Presentation.Api** as the Startup Project of your solution.

7.  In the package manager console, run the **Add-Migration** command to initialize the migrations for the database project. 
    1.  Run the command: `Add-Migration Init -Context "DataContext"`
    2.  Console must display no error message   
      ![CreateYourFirstProject-1-BIATollKit](../../Images/Tuto/AddMigrationInit.PNG)   
    3.  Verify new file *'Init'* is created:    
      ![CreateYourFirstProject-1-BIATollKit](../../Images/Tuto/AddMigrationInitFile.PNG)  

8.  In the package manager console, run the **Update-Database** command to create tables in the database . 
    1.  Run the command: `Update-Database -Context "DataContext"`
    2.  Console must display no error message
    3.  Verify tables are created in the database:   
    ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-4-Tables.PNG)

9.  Be sure startup project is "MyCompany.MyFirstProject.Presentation.Api".   
Run it. 
    
1.  The swagger page will be open.  
Click on "BIA login" at bottom right.  
The button will be green.  
    ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-5-Swagger.PNG)
    
1.  If the button is red it is probably an error in bianetconfig.Example_Development.json? You can debug the function LoginOnTeamsAsync in 02 - Application\MyCompany.MyFirstProject.Application\User\AuthAppService.cs to understand the problem.

2.  Run VS code and open the folder "C:\Sources\Test\MyFirstProject"
    
3.  Open a new terminal (Terminal > New Terminal) and enter the command:
    ```ps
    cd .\Angular\
    npm install
    npm start
    ```
    ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-6-VSCode.PNG)

4.  Open a browser at address http://localhost:4200/ (IIS express in Visual studio should be always running)  
    ![CreateYourFirstProject-1-BIATollKit](../../Images/GettingStarted/CreateYourFirstProject-7-Application.PNG)