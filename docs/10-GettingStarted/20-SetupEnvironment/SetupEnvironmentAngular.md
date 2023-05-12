---
layout: default
title: Setup angular environment
parent: Setup environment
grand_parent: Getting Started
nav_order: 1
---

# Setup angular development environment:

## Minimum requirement

### Node.js
Install the same version of node.js as the one installed on the build server ([16.16.0](https://nodejs.org/download/release/v16.16.0/))   
Choose either the x64 msi version or if you choose a zip version, modify the PATH env variable to add the path to the nodejs folder containing the npm command
To check the installed version of [node.js](https://nodejs.org/en/download/releases/), use the following command: `node -v`   
If you work behind a company proxy, run the following command to configure the proxy for npm : 
> npm config set proxy **add_your_proxy_url_here**

### Align npm version
The npm version should be align on the node version (https://nodejs.org/fr/download/releases/)
To install the version 8.11.0 (corresponde to node V16.16.0) run the following command:
```npm install -g npm@8.11.0```

### (Optionnal) Instal Angular globaly
Use to create a new Angular empy project at the last version. (but not requiered by creation with BIAToolkit):
```npm install -g @angular/cli@13.3.9```

### install project npm packages (including angular)
Go to the Angular folder and run the followind command  `npm install`   

### Visual Studio Code
Install [Visual Studio Code](https://code.visualstudio.com/Download) and add the following extensions:
* adrianwilczynski.csharp-to-typescript
* alexiv.vscode-angular2-files
* Angular.ng-template
* danwahlin.angular2-snippets
* donjayamanne.githistory
* esbenp.prettier-vscode
* johnpapa.Angular2
* kisstkondoros.vscode-codemetrics
* Mikael.Angular-BeastCode
* ms-dotnettools.csharp
* ms-vscode.powershell
* ms-vscode.vscode-typescript-tslint-plugin
* ms-vsts.team
* msjsdiag.debugger-for-chrome
* PKief.material-icon-theme
* shd101wyy.markdown-preview-enhanced
* VisualStudioExptTeam.vscodeintellicode
* yzhang.markdown-all-in-one

### Chrome Extension
* [Redux DevTools](https://github.com/reduxjs/redux-devtools/)