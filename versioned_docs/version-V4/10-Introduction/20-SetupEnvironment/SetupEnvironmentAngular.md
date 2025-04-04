---
sidebar_position: 1
---

# Setup angular development environment:

## Minimum requirement

### NodeJS and NPM With Admin right
#### Node.js
Install the same version of node.js as the one installed on the build server ([20.11.1](https://nodejs.org/download/release/v20.11.1/))   
Choose either the x64 msi version or if you choose a zip version, modify the PATH env variable to add the path to the nodejs folder containing the npm command
To check the installed version of [node.js](https://nodejs.org/en/download/releases/), use the following command: `node -v`   
If you work behind a company proxy, run the following command to configure the proxy for npm : 
> npm config set proxy **add_your_proxy_url_here**

To be able to compile Angular projects that use a version lower than 13, add this line to your .npmrc file
> node-options="--openssl-legacy-provider"
#### Align npm version
The npm version should be align on the node version (https://nodejs.org/fr/download/releases/)
To install the version 10.2.4 (correspond to node V20.11.1) run the following command:
```npm install -g npm@10.2.4```

### NodeJS and NPM Without Admin right
* Download a zip of the 64-bit Windows binary https://nodejs.org/download/release/v20.11.1/node-v20.11.1-win-x64.zip
* Create folder %USERPROFILE%\bin\nodejs, then extract the zip contents into this folder
* Open Command Prompt and set environment variables for your account
```cmd
 setx NODEJS_HOME "%USERPROFILE%\bin\nodejs\node-v20.11.1-win-x64"
 setx PATH "%NODEJS_HOME%;%PATH%"
```
* Restart Command Prompt
* Confirm installation
```cmd
 node --version
 npm --version
```

### (Optional) Instal Angular globally
Use to create a new Angular empy project at the last version. (but not required by creation with BIAToolkit):
```npm install -g @angular/cli@16.2.12```

### install project npm packages (including angular)
Go to the Angular folder and run the following command  `npm install`   

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
* PKief.material-icon-theme
* shd101wyy.markdown-preview-enhanced
* VisualStudioExptTeam.vscodeintellicode
* yzhang.markdown-all-in-one

### Chrome Extension
* [Redux DevTools](https://github.com/reduxjs/redux-devtools/)