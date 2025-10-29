---
sidebar_position: 1
---

# BIA Templates

This document explains how the configure and maintain the BIA templates used by the BIAToolKit when creating or migrating a project.

## Principle
When packaging a new version of BIA Framework, the project `BIADemo` is used as template reference to create the `BIATemplate` of the new BIA Framework version.  

To have the correct templates for a BIA Framework version, we need to configure some areas in the code to :
- ignore some portions from `BIADemo` when creating the `BIATemplate` (the script used are listed into [this documentation](../20-PackageTheFramework.md/#prepare-biatemplate))
- ignore some files when creating or migrating a project with the **BIAToolKit** from the `BIATemplate` release

## Files exclusion
### Back-end : BIADemo Only markup
Added at the top of `.cs` files, the markup `// BIADemo Only` will consider the current file as part of `BIADemo` only, and will be ignored when the packaging script will be executed.

### Front-end : folders exclusion
Into the packaging script related to the Angular part, the folders of the features specific to `BIADemo` must be removed after the copy of all the Angular project.

## Excluded code area markups
Code area identified by a begin markup starting with `Begin` and ending with `End` that will be ignored when templating the project `BIADemo` to `BIATemplate`.  

:::info
These code portions will be removed when packaging `BIADemo` to `BIATemplate` with the packaging scripts.
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
