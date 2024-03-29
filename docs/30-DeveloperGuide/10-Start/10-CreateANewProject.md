---
layout: default
title: Create a new project
parent: Start
grand_parent: Developer guide
nav_order: 10
---

# Create a new project

If you want to start a new project, you have to create the Frontend and/or the Backend project(s) depending on your needs.

You have to respect the structure below for your project :  

![Structure of Project's folder](../../Images/folderStructure.png)

To accomplish this, follow the steps below in the right order : 
1. Create and clone a Git repository for the project from Azure DevOps, GitLab or GitHub...
2. Create the project using the BIAToolKit in this folder. [Step desribe here](../../30-DeveloperGuide/50-BIAToolKit/20-CreateProject.md).
3. Update the README.md file with a descripion of your project.
4. Prepare the DotNet project :
* Prepare the Presentation WebApi:
	* Follow the steps "Prepare the Presentation WebApi" in [Presentation API project](../../30-DeveloperGuide/40-Back/10-PresentationApiProject.md)
* Prepare the database
	* Follow the steps " Preparation of the Database" in [Infrastructure data project](../../30-DeveloperGuide/40-Back/30-InfrastructureDataProject.md)

Your should now be able to launch you project !


