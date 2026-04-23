---
sidebar_position: 1
---

# Customize Application Theme
## PrimeNG Theme
PrimeNG use since **v19** the `design-token` theming ([guide](https://www.contentful.com/blog/design-token-system/)).  
Official documentation of PrimeNG Theming can be found [here](https://v19.primeng.org/theming).  

Into BIAFramework, the entry point of this theme is located at `src\app\shared\theme.ts` :
``` typescript title="theme.ts"
const MyPreset = definePreset(Material, {
    primitive: {...},
    semantic: {...},
    components: {...}
});

export const appConfig: ApplicationConfig = {
  providers: [
    provideAnimationsAsync(),
    providePrimeNG({
      inputStyle: 'outlined',
      theme: {
        preset: MyPreset,
        options: { darkModeSelector: '.dark-theme' },
      },
    }),
  ],
};
```

You'll find into `primitive`, `semantic` and `components` all preconfigured design tokens used into the PrimeNG components and the BIAFramework by using associated CSS variables. Simply change the values of these tokens to customize your application theme.

A [dedicated designer](https://primeng.org/designer) has been released by PrimeNG to help you create your own style.

## BIA Theme
Principal style is located at `src\styles.scss`.  
Custom theme is located at `src\scss\_app-custom-theme.scss`.  
All customization styles are located at `src\scss\bia` folder.

## Application Logo
### Set logo
1. Go to your Angular project
2. Open the file `src\environments\all-environments.ts`
3. Set the `urlAppIcon` property into the const `allEnvironments`
``` typescript title="all-environments.ts"
export const allEnvironments = {
  // ...
  urlAppIcon: 'assets/bia/img/AppIcon.svg',
  // ...
};
```
### Change logo color (SVG only)
:::info
This part is only applicable to `.svg` logo images with black borders
:::

1. Go to your Angular project
2. Open the file `src\scss\_app-custom-theme.scss`
3. Identifiy the HEX color to apply to your logo. Ideally, choose the same color as the `--topbar-menu-button-bg` set on the same file.
4. Go to (https://codepen.io/sosuke/pen/Pjoqqp), set the target color and compute the filter
5. Copy the value of the generated `filter`
6. Set the value of `--topbar-logo-filter` with the value
``` scss title="_app-custom-theme.scss"
:root {
  // Customize your topbar menu button color
  --topbar-menu-button-bg: #98d404;
  --topbar-menu-button-hover-bg: #5ea204;

  // Customize your logo filter color
  // Use https://codepen.io/sosuke/pen/Pjoqqp
  // -> Choose the hexadecimal value of --topbar-menu-button-bg
  --topbar-logo-filter: invert(76%) sepia(18%) saturate(4644%) hue-rotate(30deg)
    brightness(101%) contrast(97%);
}
```

## Update PrimeNG Ultima Theme
:::info
This section is for updating of PrimeNG Ultima Theme to new version only
:::
### License
The PrimeNG theme chosen for this framework is the <a href="https://www.primefaces.org/ultima-ng/">Ultima theme</a>.

To customize the BIA theme and regenerate the css from the scss files you should buy this theme <a href="https://www.primefaces.org/store/templates.xhtml">here. Click PrimeNG + "BUY" on ultima theme</a>. Adapt the license to your need (commercial or not).

A zip will be provide by primeface. It contains a Sass folder.

### Guide
In the projects generated with the bia framework, the content of the theme can be found in the following folders :
**src/assets/bia/primeng**

It should be complete by the files provide by primeface:
- Copy all folders in primeface styles folder to your project sass folder.
- Example for V19.0.0: 
    (Ultima Themes\ultima-ng-19.0.0\src\assets\layout\styles => Angular\src\assets\bia\primeng\sass ). 
    Copy the folders :
    * layout

You must install [dart-sass](https://sass-lang.com/dart-sass/) as Dart Library
=> Just [downloading the SDK as a zip file](https://dart.dev/get-dart/archive)
=> Don't forget to add its bin directory is on your PATH

Run the dependency resolver (it can required to configure or bypass proxy...)
``` cmd
 dart pub get
```

You can adapt the files in folder to customize PrimeNG Ultima Theme to BIA Framework globally
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

Rename those files with a MD5 Hash of each files with this site: <a href="https://emn178.github.io/online-tools/md5_checksum.html">md5 checksum</a>.  

And change the Angular/src/index.html and index.prod.html to use those new files.