---
sidebar_position: 1
---

# Customize Application Logo
## Set logo
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
## Change logo color (SVG only)
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


