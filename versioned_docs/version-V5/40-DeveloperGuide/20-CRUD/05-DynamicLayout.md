---
sidebar_position: 1
---

# Dynamic Layout
:::warning 
DynamicLayout is necessary in V5+ of the framework if you want to use the clone feature for your CRUD items.

You need to update your module file to use DynamicLayoutComponent by using this script on your project:

Download the [migration script](../Scripts/Migrate_to_DynamicLayout.ps1) ([.txt - Save link as](./Scripts/Migrate_to_DynamicLayout.txt)), then :
- change source path of the migration script to target your project root and your Angular project
- run it for each of your Angular project (change the Angular source path each time)
:::

## What is it?
The Dynamic Layout is a component that encapsulate the whole pages of your feature and display each one in a layout of your preference.
That way you can display the table in full page, the edit item form in a split page, the new item form in a popup and also allow dynamic changes to these choices if needed.

### Fullpage
The fullpage mode will only display the component (and its children) while masking its parent.

### Popup
The popup mode will display the component in a popup while the parent is still visible behind it.

### Split page
The split page mode will display the component on the right side of the parent component, allowing to see and interact with both at the same time.

## How to use it?
To use the Dynamic Layout you need to set the base of your route as the DynamicLayoutComponent, then give the informations necessary for the feature in the data of the route as follows:

```typescript
export const ROUTES: Routes = [
  {
    path: '',
    data: {
      breadcrumb: null,
      permission: Permission.MyFeature_List_Access,
      injectComponent: MyFeaturesIndexComponent,
      configuration: myFeatureCRUDConfiguration,
    },
    component: DynamicLayoutComponent,
    canActivate: [PermissionGuard],
    // [Calc] : The children are not used in calc
    children: [
```

### Parent configuration
**injectComponent** is the only mandatory parameter for the DynamicLayoutComponent to work:
- **injectComponent** is the main component of the feature. The parent displayed when accessing the base route of the feature.
- **configuration** is the CrudConfig of the feature. If not given, each children will need to indicate their layout mode manually. If given, the default layout mode will be set to popup, fullpage or splitPage depending on the setup inside the CrudConfig object.
- **maxScanDepth** is the max depth of the routing to find a children. It is by default at 3 (children of children of children of the DynamicLayoutComponent) but can be increased if your feature has more complex routing.
- **heightOffset** is the offset for the height of the right side container in split page mode. By default, it is set to fill the height of the page by adding 1.5rem. If you have some custom items displays on top or bottom of your components, you can set this value to change the offset to an appropriate number.
- **leftWidth** is the width (in percentage of the space) allocated to the left side (parent) container in split page mode. It is by default at 70, letting 30% of the width to the children component on the right side. This value can be set on any children of the DynamicLayoutComponent, allowing for different configurations depending of the childrens.
- **minLeftWidth** is the minimum width (as a string) allocated to the left side (parent) container in split page mode. It is by default at 36rem.
- **minRightWidth** is the minimum width (as a string) allocated to the right side container in split page mode. It is by default at 25rem.
- **allowSplitScreenResize** determine if the split page can be resized by the user to allow more or less width to each container. By default, the resize is allowed.
  
### Children configuration
- **title** gives the title of the popup in popup mode. This is translated, so a tranlation key can be set.
- **style** is the CSS style for the popup in popup mode. You can set the width, max-width, etc. for the popup through that parameter.
- **maximizable** determines if the popup is maximizable in popup mode. Set by default to true.
- **leftWidth** is the width (in percentage of the space) allocated to the left side (parent) container in split page mode. It is by default at 70, letting 30% of the width to the children component on the right side.
- **minLeftWidth** is the minimum width (as a string) allocated to the left side (parent) container in split page mode. It is by default at 36rem.
- **minRightWidth** is the minimum width (as a string) allocated to the right side container in split page mode. It is by default at 25rem.
- **layoutMode** override the layout mode set in the crudconfig sent to the parent in **configuration**. If the configuration indicates that all children should be in popup, **layoutMode** allows to bypass that for that children. Should always be set if the **configuration** is not set for the DynamicLayoutComponent.

Example of some child routes in a dynamic layout parent:
```typescript
  {
    path: 'edit',
    data: {
      breadcrumb: 'bia.edit',
      canNavigate: true,
      permission: Permission.Plane_Update,
      title: 'plane.edit',
    },
    component: PlaneEditComponent,
    canActivate: [PermissionGuard],
  },
  {
    path: 'historical',
    data: {
      breadcrumb: 'bia.historical',
      canNavigate: false,
      layoutMode: LayoutMode.popup,
      style: {
        minWidth: '50vw',
      },
      title: 'bia.historical',
      permission: Permission.Plane_Read,
    },
    component: PlaneHistoricalComponent,
    canActivate: [PermissionGuard],
  },
  {
    path: 'engines',
    data: {
      breadcrumb: 'app.engines',
      canNavigate: true,
      permission: Permission.Engine_List_Access,
      layoutMode: LayoutMode.fullPage,
    },
    loadChildren: () =>
      import('./children/engines/engine.module').then(
        m => m.EngineModule
      ),
  },
```

- *edit* route LayoutMode is not set so it will use the default layout mode given in the feature configuration. If in popup mode, the title will be 'plane.edit'.
- *historical* route will always be opened in a popup. Title of the popup will be 'bia.historical' and the popup min width will be 50vw.
- *engines* will always be shown in full page, taking all the space for itself.