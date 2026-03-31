---
sidebar_position: 1
---

# Analyze the size of the application
This document explains how to create a stats report that give an overview of the size of the js generated with the Angular application.   
![Stats](../Images/Stats.PNG)

## Prerequisite
You should install esbuild-visualizer : 
* In the terminal run the command:
```cmd
npm i -g esbuild-visualizer
```
The doc of this project is [here](https://github.com/btd/esbuild-visualizer).

## Generate the stat
Run the command:
```cmd
npm run stats
```

=> The stats will appear in a web browser with the file Angular/dist/BIADemo/stats.html.
=> different size appear the size to challenge is the parsed size. At the end the real size will be the parsed size or the gziped depending on how is configured your production server.

## Additional references:
* [Optimize Angular bundle size in 4 steps](https://medium.com/angular-in-depth/optimize-angular-bundle-size-in-4-steps-4a3b3737bf45)
* [Enable GZIP compression](https://social.msdn.microsoft.com/Forums/en-US/2483ba9a-5d22-438b-a9bb-f476bad5ffce/iis-10-enable-gzip-compression?forum=aspconfiganddeploy)