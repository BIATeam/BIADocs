---
layout: default
title: Create a new project
nav_order: 50
---

# Create a new project

If you want to start a new project, you have to create the Frontend and/or the Backend project(s) depending on your needs.

You have to respect the structure below for your project :  

![Structure of Project's folder](./Images/folderStructure.png)

To accomplish this, follow the steps below in the right order : 
1. Create and clone a Git repository for the project from Azure DevOps, GitLab or GitHub...
2. Create the project using the BIAToolKit in this folder. [Step desribe here](./BIAToolKit/CREATE.md).
3. Update the README.md file with a descripion of your project.
4. Prepare the DotNet project :
* Prepare the Presentation WebApi:
	* Follow the steps "Prepare the Presentation WebApi" in [01 - PRESENTATION.API.md](./Projects/01-PRESENTATION.API.md)
* Prepare the database
	* Follow the steps " Preparation of the Database" in [04 - INFRASTRUCTURE.DATA.md](./Projects/04-INFRASTRUCTURE.DATA.md)

Your should now be able to launch you project !


