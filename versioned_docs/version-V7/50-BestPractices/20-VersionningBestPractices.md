---
sidebar_position: 1
---

# Version best practices

The goal of this page is to harmonize the versioning usage for all projects build with the BIAFramework.

## Common strategy:
- The version string 1.2.3 indicates major version 1, minor version 2, and fix 3

### When update the major version:
- For a full stack project: 
  - When several screens changes or the way of navigation.
  - For an huge development change. (i.e. > 30 man day)
- For a web api project:
  - Incompatible API changes
  
### When update the minor version:
- For a full stack project: 
  - Adding new functionality, new screen or change a display.
  - Other minor change.
- For a web api project:
  - Adding new functionality in a backward-compatible manner.

### When update the fix:
- For a bug fix only.

## Where change the version
One time the version is determined you should change it:
- In the back source in **DoteNet\Company.Project.Crosscutting.Common\Constants.cs**
  - You have 2 variables : BackEndVersion and FrontEndVersion. They can be different if you do not want to force the reload of the front after a minor change or bug fix in back part.
  - But 
    - the FrontEndVersion should be the same than in the front source.
    - the BackEndVersion should always be equals or greater than FrontEndVersion.
- In the front source in **Angular\src\environments\all-environments.ts**  
- At the creation of the release with GitFlow at format V1.2.3 (see : [Git Branching best practices](./10-GitBranchingBestPractices.md))
- At the deployment you have to specified the version name at format V1.2.3.

