---
sidebar_position: 180
---

# Use custom icons instead on primeng icons
## Why ?

Primeng Icons are limiting and often aren't specific enough to convey the exact meaning of an action or feature.
You might want to have a customized icon that is more telling for a menu or a button.

## How ?

You will first need an icon (preferably square sized). In this example I'll use an svg icon but it works with most image format. It is recommanded to use SVG for the scalability. You can convert img to svg using external sites like https://png2svg.com/fr/. That icon will be stored in the assets of the application (In this example in assets/img).

You can then either add a css class for each of your icons in the _app-custom-theme.scss or create a new dedicated file for all your custom icons. If you create a new file, include it in your angular.json "styles" section.

The class for each icon will look like that (ci is for Custom Icon but you can use whatever naming you want):

```css
.ci {
  width: 1.7rem;
  height: 1.7rem;
  background-size: contain;
  background-repeat: no-repeat;
  filter: invert(36%) sepia(11%) saturate(574%) hue-rotate(167deg)
    brightness(90%) contrast(88%);
}

.ci-my-icon-1 {
  width: 1.6rem;
  height: 1.6rem;
  background-image: url('/assets/img/my-svg-file-1.svg');
}

.ci-my-icon-2 {
  background-image: url('/assets/img/my-svg-file-2.svg');
}
```

Since it's a background-img with no content, the width and height needs to be defined for the icon to take some space. You do multiple class with different width and height if needed in multiple size in the application.

You can now use your icon where you would normally use a primeng icons with class "pi pi-*".

```html
    <div class="flex justify-content-center">
        <i class="pi pi-lock"></i>
    </div>
```
would become :
```html
    <div class="flex justify-content-center">
        <i class="ci ci-complex-lock"></i>
    </div>
```

It also works for the menu icons of the application by passing your custom class in the icon property of BiaNavigation in navigation.ts :
```ts
export const NAVIGATION: BiaNavigation[] = [
  {
    labelKey: 'app.sites',
    permissions: [Permission.Site_List_Access],
    path: ['/sites'],
    icon: 'ci ci-my-custom-site',
  },
];
```
  
