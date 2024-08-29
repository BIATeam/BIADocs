---
layout: default
title: Create an OPTION
parent: CRUD
grand_parent: Developer guide
nav_order: 30
---

# Create an OPTION
This document explains how to quickly create a option module in domain. It will be use to populate combo list and multiselect in features forms.   
<u>For this example, we imagine that we want to create a new feature with the name: <span style="background-color:#327f00">aircrafts</span>.   </u>

## Prerequisite
The back-end is ready, i.e. the <span style="background-color:#327f00">Aircraft</span> controller exists as well as permissions such as `Aircraft_Option`. This controller should have a GetAllOptions function that return a list of OptionDto

## Create a new domain manually
First, create a new <span style="background-color:#327f00">aircrafts</span> folder under the **src\app\domains** folder of your project.   
Then copy, paste and unzip into this feature <span style="background-color:#327f00">aircrafts</span> folder the contents of :
  * **Angular\docs\domain-airport-option.zip** 

Then, inside the folder of your new feature, execute the file **new-option-module.ps1**   
For **new option name? (singular)**, type <span style="background-color:#327f00">aircraft</span>   
For **new option name? (plural)**, type <span style="background-color:#327f00">aircrafts</span>   
When finished, you can delete **new-option-module.ps1**   

## Create a new domain automatically
Use the BIAToolKit on [CRUD Generation](../../30-BIAToolKit/50-CreateCRUD.md) tab with (at least) 'Front' (for generation) and 'Option' (for Generation Type).<br>
Don't forget to fill option name on singular (i.e. aircraft) and plural form (i.e. aircrafts).