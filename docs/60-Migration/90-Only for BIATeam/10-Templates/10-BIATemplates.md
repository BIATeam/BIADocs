---
sidebar_position: 1
---

# BIA Templates

This document explains how the configure and maintain the BIA templates used by the BIAToolKit when creating or migrating a project.

## Principle
When packaging a new version of BIA Framework, the project `BIADemo` is used as template reference to create the associated `BIATemplate` for the new version

To have the correct templates for a BIA Framework version, we need to configure code of `BIADemo` and packaging scripts in order to :
- ignore some code areas from `BIADemo` when creating the `BIATemplate`
- ignore some files when creating or migrating a project with the **BIAToolKit** from the `BIATemplate` release

:::info
The script used for packaging are listed into [this documentation](../20-PackageTheFramework.md/#prepare-biatemplate)
:::

## Folders exclusion
:::info
Only applicable for Angular project template
:::

Into the packaging script related to the Angular part, the folders of all the features specific to `BIADemo` must be removed after the copy of all the Angular project.

## BIADemo Only markup
:::info
Only applicable to `.cs` files
:::

Adding at the top of a file the markup `// BIADemo Only` will consider the current file as part of `BIADemo` only, and will be ignored when the packaging script is executed.

## Excluded code area markups
Code area identified by a begin markup starting with `Begin` and ending with `End` that will be ignored when templating the project `BIADemo` to `BIATemplate`.  

:::info
These code areas will be removed when packaging `BIADemo` to `BIATemplate` with the packaging scripts.
:::
:::tip
Prefix theses markups by the following according to the file type :
- `.cs` : `// {Markup}`
- `.ts` : `// {Markup}`
- `.json` : `// {Markup}`
- `.html` : `<!-- {Markup} -->`
:::

### BIADemo 
**Markup begin** : `Begin BIADemo`  
**Markup end** : `End BIADemo`
:::info
Code in these areas is specific code related to `BIADemo`
:::

### BIAToolkit Generation Ignore
**Markup begin** : `Begin BIAToolkit Generation Ignore`  
**Markup end** : `End BIAToolkit Generation Ignore`
:::info
Code in these areas is specific code related to `BIADemo` but required to perform the unit tests of BIAToolKit Templates ([see documentation](./20-BIAToolKitTemplates.md#unit-tests)).
:::

## Except BIADemo markup
Into the code, the markup `// Exception BIADemo ` will be replaced by an empty string in order to apply the next instruction when packaging the `BIATemplate`.

:::tip
It must be used before a [BIADemo](#biademo) excluded code area.
:::

``` csharp title="BIADemo (before packaging)"
public class Example
{
    // Except BIADEMO public const string Version = "0.0.0";
    // Begin BIADemo
    public const string Version = "1.0.0-beta";
    // End BIADemo
}
```

``` csharp title="BIATemplate (after packaging)"
public class Example
{
    public const string Version = "0.0.0";
}
```
- Code between markups `BIADemo` has been removed
- `// Except BIADEMO ` has been deleted to use the next code of the line

## Template Features
Into the `.bia` folder of `BIADemo` (and any `BIATemplate` version) exists the file `BiaToolKit_FeatureSetting.json` that enumerates the differente features available for the current BIA Framework version used by the `BIATemplate`.  
These features are used by the **BIAToolKit** to create or migrate a project. The configuration of them is usefull to exclude some code, folders or files when they are selected or not.

``` json title="BiaToolKit_FeatureSetting.json"
[
  {
    "Id": 1,
    "DisplayName": "Feature 1",
    "Description": "First example feature",
    "IsSelected": true,
    "Tags": [
      "BIA_FEATURE1_TAG"
    ],
    "FoldersToExcludes": [
      ".*FolderToExclude.*$"
    ],
    "DisabledFeatures": [2]
  },
  {
    "Id": 2,
    "DisplayName": "Feature 2",
    "Description": "Second example feature",
    "IsSelected": true,
    "Tags": [
      "BIA_FEATURE2_TAG"
    ]
  },
]
```
You can configure for each feature :
- `Id` : the unique identifier of the feature
- `DisplayName` : the display name of the feature (display value of the feature list from the BIAToolKit)
- `Description` : the description of the feature (displayed into the tooltip of the feature from the BIAToolKit)
- `IsSelected` : default selection of the feature for the current project creation or migration
- `Tags` *(optionnal)* : list of tags that are related to the current feature used into `BIADemo` (then `BIATemplate` one packaged) to identify code that is specific to the feature, and excluded if the feature is not selected when creating or migrating a project
  :::info
   All tags should began with `BIA_`
  :::
- `FoldersToExcludes` *(optionnal)* : list of folders regex from the `BIATemplate` to exclude for the project creation or migration 
- `DisabledFeatures` *(optionnal)* : list of feature's identifier that will be disabled automatically when the current one is not selected
  

:::tip
Change the order of the features display into the **BIAToolKit** by changing the order of the features into the `.json`
:::

### Tags usage
#### .NET conditions
First, you must declare your `BIA_FEATURE_TAG` as project constant into all the target `.csproj` that will be concerned by conditions with this tag into `BIADemo`
``` csharp title="BIADemoProject.csproj"
<Project Sdk="Microsoft.NET.Sdk">
	<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|AnyCPU'">
		<DebugType>portable</DebugType>
		<DebugSymbols>true</DebugSymbols>
		<DefineConstants>BIA_FEATURE_TAG</DefineConstants>
	</PropertyGroup>
	<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|AnyCPU'">
		<DebugType>portable</DebugType>
		<DebugSymbols>true</DebugSymbols>
		<DefineConstants>BIA_FEATURE_TAG</DefineConstants>
	</PropertyGroup>
</Project>
``` 
You will be able then to remove this constant to test into `BIADemo` if your conditions are working well.

:::info
All the defined constants into `BIADemo` (then `BIATemplate`) will be removed when creating or migrating a project by the **BIAToolKit**
:::

##### Remove file from project condition
Add an `ItemGroup` into your csproj like following :
``` csharp title="BIADemoProject.csproj"
<Project Sdk="Microsoft.NET.Sdk">
  	<ItemGroup Label="Bia_ItemGroup_BIA_FEATURE_TAG" Condition="!$([System.Text.RegularExpressions.Regex]::IsMatch('$(DefineConstants)', '\bBIA_FEATURE_TAG\b'))">
	</ItemGroup>
</Project>
```
- `ItemGroup.Label` must corresponds to the template `Bia_ItemGroup_{FEATURE_TAG}`
- `Condition` means that the current `ItemGroup` will be considered only if there is no defined constant `BIA_FEATURE_TAG`

Add then into your `ItemGroup` all the `Compile` instruction with `Remove` attribute for the files that must be excluded if the condition is false :
``` csharp title="BIADemoProject.csproj"
<Project Sdk="Microsoft.NET.Sdk">
    <ItemGroup Label="Bia_ItemGroup_BIA_FEATURE_TAG" Condition="!$([System.Text.RegularExpressions.Regex]::IsMatch('$(DefineConstants)', '\bBIA_FEATURE_TAG\b'))">
        <Compile Remove="**\*Pattern*.cs" />
        <Compile Remove="**\Pattern.cs" />
    </ItemGroup>
</Project>
```
Set the `Remove` attribute with following :
- `**\*Pattern*.cs` : will exclude all the files that contains `Pattern` into the `.cs` file name
- `**\Pattern.cs` : will exclude all the files that matches `Pattern.cs` file name

:::info
- These operations of file exclusion are performed by the **BIAToolKit** when creating or migrating a project
- The `ItemGroup` related to the `Bia_ItemGroup_{FEATURE_TAG}` label will be removed by the **BIAToolKit** when creating or migrating a project
:::

##### Remove project reference condition
Add a `Condition` attribute to your project reference like following :
``` csharp title="BIADemoProject.csproj"
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <ProjectReference Include="OtherProject.csproj" Condition="$([System.Text.RegularExpressions.Regex]::IsMatch('$(DefineConstants)', '\BUSE_FEATURE_TAG\b'))"  />
  </ItemGroup>
</Project>
```
Here, the project will be add as reference into `BIADemo` project only if the constant `USE_FEATURE_TAG` is defined into the project.

:::info
The project reference will be removed when creating or migrating a project with **BIAToolKit** if the corresponding feature is not selected
:::

##### Code condition
Use directly into the code the conditions with your `BIA_FEATURE_TAG` constant :
``` csharp title="MyService.csproj"
public class MyService()
{
#if BIA_FEATURE_TAG
    public void SpecificMethod()
    {
        // [...]
    }
#endif
}
``` 

You can use `#else` condition :
``` csharp title="MyService.csproj"
public class MyService()
{
#if BIA_FEATURE_TAG
    public void SpecificMethod()
    {
        // [...]
    }
#else 
    public void CommonMethod()
    {
        // [...]
    }
#endif
}
```

:::tip
You can use `||` and/or `&&` operators into your condition declaration between different tags (only support top level conditions)
:::

#### Other cases
Simply use the tags as code area as seen for [.NET part](#net-conditions) like following :
``` json title="example.json"
{
    // if BIA_FEATURE_TAG || BIA_OTHER_FEATURE_TAG
    "specificCode": "example"
    // endif
}
```
``` typescript title="example.ts"
export class Example
{
    // if BIA_FEATURE_TAG && BIA_OTHER_FEATURE_TAG
    specificCode: string;
    // endif
}
```
:::warning
Only compatible for `// if {FEATURE_TAG}` and `// endif` markups
:::