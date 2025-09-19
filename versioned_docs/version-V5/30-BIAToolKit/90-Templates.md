---
sidebar_position: 1
---

# Templates
This document explains how the BIAToolkit use templates to generate Option, DTO and CRUD features

## Diagram
![Diagram](../Images/BIAToolKit/TemplatesDiagram.png)

1. Developper wants to generate a feature (Option, DTO, CRUD) for his BIA Framework project using the BIAToolKit
2. A file generator context is created based on the selected feature to generate
3. The file generator service gets the current project BIA Framework Version (X.Y.Z) from the `Constants.cs` file of the .NET sources
4. The file generator asks for the corresponding model provider according to the current project version (X.Y.Z)
5. A feature model corresponding to the target framework version and feature to generate is created
6. The model provider read the template's manifest of the correspondings feature kind and project version
7. Each entry of the manifest use the template file based on the feature model data to generate the file
8.  The generatd file is created and copied or included into his target directory or file where the path is provided by the manifest

## Version Templates
The templates for a dedicated version (or a range) corresponding to a bunch of various elements :
- The **templates** `.tt` used to generate the files
- The **models** used to inject data into the templates
- The **mocks** of the models used to simulate data when creating the templates
- The **manifest** used to list the templates data (`.tt` file and target file into the project) that must be used for each feature kind

Each bunch corresponds to a breaking changes version of the BIA Framework. It means that if you have a minor version that provides any changes of one of the files that must be generated using the templates, you will have a dedicated bunch of templates for this version.  

Commonly, there is a new bunch created for each major version.  
Unless a new major version, the bunch must covered all versions until the new one.

:::info
The bunch are located into the `BIA.ToolKit.Applications.Templates`  

<u>**Example**</u> :  
The templates for the version **5.0.0** will be located into the namespace `BIA.ToolKit.Applications.Templates._5_0_0`.  
They will be used for all the versions **5.*** unless a new breaking minor version is released : here, the **5.1.0**.  
In that case, the new templates will be located into the namespace `BIA.ToolKit.Applications.Templates._5_1_0`.
:::
:::tip
The new bunch must be copied from the previous one and adapted for each concerned elements : 
1. Copy the previous folder and rename it with your new version identifier **_X_Y_Z**
2. Rename in this folder old **_X_Y_Z** references to new **_X_Y_Z**
3. Do the same for **X.Y.Z** references between old and new
:::

### Models
Templates models corresponds to the model of data that will be used into the templates files `.tt` to generate the files for a dedicated feature.  

It must exists a model for each kind of feature to generate, and a dedicated interface for them.

:::info 
The templates models are located into the namespace `BIA.ToolKit.Applications.Templates._X_Y_Z.Models`  

The templates models common elements are located into the namespace `BIA.ToolKit.Applications.Templates._X_Y_Z.Common`  

The templates models interfaces are located into the namespace `BIA.ToolKit.Applications.Templates._X_Y_Z.Common.Interfaces`  

:::
### Mocks
Mocks are simply templates models implementation used into the templates files `.tt` to simulate data when editing the template file.

:::info 
The templates mocks are located into the namespace `BIA.ToolKit.Applications.Templates._X_Y_Z.Mocks`
:::
### Templates files
### Manifest
## File Generator Service
### Model Provider
### Context