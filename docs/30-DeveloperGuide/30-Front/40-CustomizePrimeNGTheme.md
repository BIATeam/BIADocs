---
layout: default
title: Customize PrimeNG Theme
parent: Front
grand_parent: Developer guide
nav_order: 40
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

You must install [dart-sass](https://sass-lang.com/dart-sass/) as Dart Library
=> It is possible to just [downloading the SDK as a zip file](https://dart.dev/get-dart/archive)
=> don't forget to add its bin directory is on your PATH

You can adapt the files in folder
* src/assets/bia/primeng/bia
* src/assets/bia/primeng/bia/overrides
* src/assets/bia/primeng/bia/overrides/customs
* src/assets/bia/primeng/layout (except styles folder)

Once the changes have been made run
``` cmd
npm run styles
```

It will regenerate :
* src/assets/bia/primeng/layout/style/layout/layout.css
* src/assets/bia/primeng/layout/style/theme/theme-dark/theme-dark.css
* src/assets/bia/primeng/layout/style/theme/theme-light/theme-light.css

Rename those files with a MD5 Hash of each files with this site: <a href="https://emn178.github.io/online-tools/md5_checksum.html">md5 checksum</a>.  
