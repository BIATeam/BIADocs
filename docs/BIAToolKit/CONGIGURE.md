---
layout: default
title: Configure the BIA tool kit 
parent: BIAToolKit
nav_order: 1
---

# Configure the BIA tool kit
This document explains how to configure the BIA tool kit, to be ready to apply the other operation (creation, migration...)

![BIAToolKitConfig](../Images/BIAToolKit/Config.PNG)

## Get the BIAToolKit
Take the last version of the BIAToolKit from [release](https://github.com/BIATeam/BIAToolKit/releases) or from your company ClickOnce folder if you have one. 

## Configure your BIA Template repository
In the first tab, in the upper left corner, chose if you want to use a local folder to synchronise it.
* It is not requiered so if you don't have clone the BIATemplate localy select the first radio button "Use the BIAtemplate GitHub repository" the local folder will be : C:\Users\YourLogin\AppData\Local\BIA.ToolKit\BIA.ToolKit\1.0.0\BIATemplate\Repo
* If you work regulary on BIATemplate or if you synchronize regulary you select the second option "use a local cloned folder" and enter the local pat of this folder.

Click on the "synchronize" button to do a git sync between the GitHub repo and the local folder.

## Use company files 
The Company files are use to remplace some files like logos, congifiguration files at the creation of the project or during migration.
The company files can be a shared folder or a git repository.

It is not necessary but it is recommanded to have those files if you implement severals projects with the framework. It avoid you to manualy make the replacement on each project.

If you do not have company files check the check box in the right part.
Select if you want to use a git repo or a local folder.
The synchronize work only if you have configure the repo url.

## Save the settings
Click on the save settings button to save the settings. The configuration is save for the next start of the BIAToolKit