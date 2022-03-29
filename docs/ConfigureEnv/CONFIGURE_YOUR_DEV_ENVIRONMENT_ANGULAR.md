---
layout: default
title: Configure your angular development environment
parent: Configure your environment
nav_order: 1
---

# Configure your angular development environment:

## Minimum requirement

### Node.js
Install the same version of node.js as the one installed on the build server ([12.18.3](https://nodejs.org/download/release/v12.18.3/))   
Choose either the x64 msi version or if you choose a zip version, modify the PATH env variable to add the path to the nodejs folder containing the npm command
To check the installed version of [node.js](https://nodejs.org/en/download/releases/), use the following command: `node -v`   
If you work behind a company proxy, run the following command to configure the proxy for npm : 
> npm config set proxy **add_your_proxy_url_here**

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