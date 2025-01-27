---
sidebar_position: 160
---

# Configure Layout of application with V4.0.0 design
Starting at V4.0.0, a new layout is available for applications. Menu is on the sidebar.
There is some configurations that could be usefull depending of your need with your application
## Change footer height
You can change the default height of the footer by changing the css variable --footer-height in your _app-custom-theme.scss and change the default 4rem by the value you need. Example for a 3 rem header :
```css
bia-ultima-layout {
  --footer-height: 3rem;
}
```

## Change sidebar width
By default the sidebar is 17rem width. 
You might need to get that sidebar larger for some reasons.
If the title of your application doesn't fit the default 17rem, we recommand using an acronym of shortening it. If you can't, you can change the width by setting the css variable --sidebar-width in your _app-custom-theme.scss. For example for a 22rem width sidebar :
```css
bia-ultima-layout {
  --sidebar-width: 22rem;
}
```

## Configure the layout
### Set default style
The layout can be configured in different ways :
You can change :
- the color scheme (light or dark)
- the sidebar / menu mode
- the footer mode
- the scale of the application
- show or hide the user avatar

And you can even chose to opt out of the new layout and return to pre 4.0.0 layout if needed.

To configure all that you can set the values you want in your app.component constructor with for example :
```ts
    this.layoutService.defaultConfigUpdate({
      menuMode: 'drawer',
      footerMode: 'bottom',
      showAvatar: false,
      scale: 16,
    });
```
You can find all the fields in interface AppConfig.
The default values are :
```ts
const DEFAULT_LAYOUT_CONFIG: AppConfig = {
  classicStyle: false,
  colorScheme: 'light',
  menuMode: 'static',
  scale: 14,
  showAvatar: true,
  footerMode: 'overlay',
}
```

### Set user configuration
The layout can be configured by the user of the application.
You can decide what the user can or cannot change :
- avatar
- language
- scale
- color theme
- sidebar / menu mode
- footer mode
- classic \<-\> ultima layout

To configure all that you can set the values you want in your app.component constructor with for example :
```ts
    this.layoutService.setConfigDisplay({
      showEditAvatar: false,
      showTheme: false,
      showMenuStyle: true,
      showFooterStyle: true,
    });
```
You can find all the fields in interface ConfigDisplay.
The default values are :
```ts
const DEFAULT_CONFIG_DISPLAY: ConfigDisplay = {
  showEditAvatar: true,
  showLang: true,
  showScale: true,
  showTheme: true,
  showMenuStyle: false,
  showFooterStyle: false,
  showToggleStyle: false,
};
```
