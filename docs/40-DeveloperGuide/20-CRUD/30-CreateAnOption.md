---
sidebar_position: 1
---

# Create an OPTION
This document explains how to quickly create a option module in domain. It will be use to populate combo list and multiselect in features forms.   
**For this example, we imagine that we want to create a new feature with the name: `aircrafts`.**
## Prerequisite
The back-end is ready, i.e. the `Aircraft` controller exists as well as permissions such as `Aircraft_Option`. This controller should have a GetAllOptions function that return a list of OptionDto

## Create a new domain manually
First, create a new `aircrafts` folder under the **src\app\domains** folder of your project.   
Then copy, paste and unzip into this feature `aircrafts` folder the contents of :
  * **Angular\docs\domain-airport-option.zip** 

Then, inside the folder of your new feature, execute the file **new-option-module.ps1**   
For **new option name? (singular)**, type `aircraft`   
For **new option name? (plural)**, type `aircrafts`   
When finished, you can delete **new-option-module.ps1**   

## Create a new domain automatically
Use the BIAToolKit on [CRUD Generation](../../30-BIAToolKit/50-CreateCRUD.md) tab with (at least) 'Front' (for generation) and 'Option' (for Generation Type).

Don't forget to fill option name on singular (i.e. aircraft) and plural form (i.e. aircrafts).