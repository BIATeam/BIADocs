---
sidebar_position: 1
---

# Git Branching best practices

The goal of this page is to harmonize the git branching usage for all projects build with the BIAFramework.

The standard flow is Git flow

![GitFlow](../Images/GitFlow.png)

The strategy depend on the size of the project:

## Common strategy :
- Use a main branch and Develop branch.
- Create a release Branch for each delivery
- For hotfix create a specific branch.

## Project with 1 or 2 developers:
- Standard usage : work on Develop Branch
- For huge feature you can create a dedicated branch.
  
## Project more the 2 developers:
- Standard usage : Develop all your Features on dedicated Branch
- For very small change you can work directly on Develop Branch

## Initialize gitflow extension
- Just install the gitflow extension for VS Code.
  ![GitFlowExtension](../Images/GitFlowVSExtension.png)
- If the initialization have never be done press F1 (=shortcut to open VS Code Command Palette) and select 'GitFlow: Initialize repository for gitflow' (if you have an error at the first init, try a second one)
- ![GitFlowInitializeRepository](../Images/GitFlowInitializeRepository.png)
- Follow the command prompts and accept the defaults...

## Use the gitflow extension
- Develop on Develop branch:
  - Pull the last version of the develop branch and push small commits (~daily) on it.
- Develop on Feature branch:
  -  Type F1 + GitFlow: Feature: start
     -  Enter an explicit name for the feature. 
        => This action create the "feature\[Name of the feature]" branch.
  -  Push small commits (~daily) on this feature branch.
  -  2 solutions to finalize the feature:
     -  Type F1 + GitFlow: Feature: finish 
     -  Create a pull request from feature branch to develop. Warning **the feature branch should be delete** in case of squash validation.
  -  .... repeat for every feature ...
- To deliver in the both case:
  - Ensure you have change the version name in de constant.cs (DotNet) and environment.json (Angular) files :
  - Type F1 + GitFlow: Release: start
    - For the release name enter the name of the version at the format : Vx.y.z
  - You can verify that all compile.
  - Type F1 + GitFlow: Release: finish 
    - Enter the tag name (=version name) at the format Vx.y.z

- In case of hotFix
  - Type F1 + GitFlow: HotFix: start 
    - Enter for the name of the HotFix the new version at the format : Vx.y.z (you should increment the last digit)
  - Push small commits (~daily) on the created hotfix\Vx.y.z Branch.
  - Ensure you have change the version name in de constant.cs (DotNet) and environment.json (Angular) files to match with HotFix name.
  - Type F1 + GitFlow: HotFix: finish

## Important Notice to use GitFlow extension with branch rules:
The GitFlow extension simplify the life of the developers. But if the commit on some branches is block by a policy the final commit done by extension failed.
Generally this policy are apply on main and/or develop branches to force junior developer to do a Pull request.

If develop branch commit are locked for junior developers, they should develop on Feature branches and perform a pull request at the end (see above). They should not use the command "Feature: finish"  

If the commit on main or develop branches is lock it is impossible to finalize the operation:
 - Release: finish 
 - HotFix: finish

Is this condition some senior developer should have the right to bypass the policy and will be the only authorized to perform those actions.

To bypass policies for senior developer:
- In AzureDevOps select the repository, and menu Branches. On main and develop branches click on menu at right and "Branch Policies". After you select the senior developer and add Allow to "Bypass policies when pushing"

![AzureDevOpsBranchPolicy](../Images/AzureDevOpsBranchPolicy.PNG)

- In GitHub manage the blocking rulesets and add the senior developer in bypass list.

## Visualize the branches:
- You can use the VS Code Git Graph extension to visualize all the branches.

## External source:
* [gitflow](https://www.atlassian.com/fr/git/tutorials/comparing-workflows/gitflow-workflow/)
* [gitflow extension](https://github.com/vector-of-bool/vscode-gitflow)
* [Git Graph extension](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph)

