---
layout: default
title: Create CRUD from existing entity, mapper et Dto files
parent: BIAToolKit
grand_parent: Developer guide
nav_order: 50
---

# Create CRUD on existing project with the BIA tool kit
This document explains how to create a CRUD with the BIAToolKit.

![BIAToolKitAddCrud](../../Images/BIAToolKit/AddCRUD.PNG)

## Prerequisite
* You need to have an existing project. In other case, create it as [Describe here](./20-CreateProject.md).
* In first time, your project must contain: *entity*, *mapper* and *dto* files associated to the CRUD you want to create.
* Project must contain **.bia** folders as 
  
![ProjectFolders](../../Images/BIAToolKit/NewProject.PNG)

## 0. Choose Project Folder
Choosen the project directory to work on by choosing 'project parent path' and selecting 'project folder' ('Dto file' combobox is automatically populate).<br>
Zips contains on '.bia' folders are automatically parsed.

## 1. Choose Dto file linked to CRUD to generate
The Dto file combobox lists all Dto files on your project.<br> 
If you have created new Dto file and you don't see it, you can refresh the list with the button on right side of combobox.<br>
![DtoFiles](../../Images/BIAToolKit/SelectDto.PNG)<br>
Entity name is deducted from dto file name.<br>
Option item combobox is filled after choosen dto file.<br>
Dto file selected is automatically parsed. The 'Entity name (singular)' is filled and the 'Display item name' combobox is populated.

## 2. Select CRUD generation
Choose items you want to generate for the CRUD:
1. Generation: 
   * Back: WebAPi (selected by default)
   * Front: Front (selected by default)
2. Generation Type: (minimum a choice is mandatory)
   *  CRUD
   *  Option
   *  (and Team in the future)

![CRUDGeneration](../../Images/BIAToolKit/CRUDGeneration.PNG)

## 3. Fill CRUD name
Singular entity name is fill up by default but you can change it.<br>
You need to complete the plurial name before generation.<br>
![CRUDName](../../Images/BIAToolKit/CRUDName.PNG)

## 4. Choose display item
On associated combobox, choose the field you want to display on front page.<br>
![DisplayItem](../../Images/BIAToolKit/SelectDisplayItem.PNG)

## 5. Add option (not mandatory)
__*Option Generation Type must not be checked.*__<br>
It is possible to generate link Option with the CRUD.<br>
On associated combobox, choose 1 or more option previously generated.<br>
![DisplayOption](../../Images/BIAToolKit/SelectOptionItem.PNG)<br>
*This field is not mandatory to generate a CRUD.*

## 6. Generate CRUD
By clicking on the button 'Generate', CRUD files are generated automatically on project.

> At first CRUD generation on the project, an historic file is made on project folder (*CrudGeneration.bia*).<br>
> In case of regeneration, data are automatically filled from historic file, and warning message is displayed to inform you.
![DtoSelected](../../Images/BIAToolKit/DtoAlreadyUsed.PNG)<br>

Open DotNet and Angular projects, rebuild each one and fix issues if exists.

### <u>Known issues</u>
* After generation, on Angular folder, go to navigation file (*navigation.ts*) and rework **path** property (delete *examples*).
* On front side, when compilling angular project, if **import** are not used (mostly on model), deleted its to avoid errors.
* Traduction is not already implemented, so **i18n** files (fr.json/en.json/es.json) must be completed with missing labels. 

## Delete previous CRUD generation
In case of you want previous generation:
* in first, select the Dto file <br>
* then, click on 'Delete previous generation' button

## Delete annotations
After generations, if you want to clean code, you can choose to delete annotations. Be carreful, because in this case, <u>**you can't regenerate or delete previous features generated**</u>. But you can continue to generate new features.
