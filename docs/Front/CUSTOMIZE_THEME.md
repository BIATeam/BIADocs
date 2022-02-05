---
layout: default
title: Customize PrimeNG Theme
parent: Front
nav_order: 4
---

# Customize PrimeNG Theme
## License Ultima theme is requiered
The PrimeNG theme chosen for this framework is the <a href="https://www.primefaces.org/ultima-ng/">Ultima theme</a>.

To customize the bia theme and regenerate the css from the scss files you should by this theme <a href="https://www.primefaces.org/store/templates.xhtml">here. Click PrimeNG + "BUY" on ultima theme</a>. Adapt the license to your need (commercial or not).

A zip will be provide by primeface. It contains a Sass folder.

## Work in the project
In the projects generated with the bia framework, the content of the theme can be found in the following folders :
**src/assets/bia/primeng**

It should be complete by the files provide by primeface in sass folder. Copy the folders and file :
* layout
* theme
* variables
* _fonts.scss

You must install node-sass globally with the following command (example for node 12.18.3): 
```cmd
npm install -g node-sass@6.0.1 --unsafe-perm true.
```
In this command adapt the version of the node-sass to your installed node version. See the compatibility list <a href="https://github.com/sass/node-sass#node-sass">here</a>.

You can adapt the files in folder
* src/assets/bia/primeng/sass/overrides
* src/assets/bia/primeng/sass/overrides/customs
* src/assets/bia/primeng/layout
* src/assets/bia/primeng/theme/biaTheme

Once the changes have been made run
``` cmd
npm run all-styles
```

It will generate :
* src/assets/bia/primeng/layout/css/layout-dark.css
* src/assets/bia/primeng/layout/css/layout-light.css
* src/assets/bia/primeng/theme/biaTheme/theme-dark.css
* src/assets/bia/primeng/theme/biaTheme/theme-light.css

Rename those files with a MD5 Hash of each files with this site: <a href="https://emn178.github.io/online-tools/md5_checksum.html">md5 checksum</a>.  
