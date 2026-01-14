---
sidebar_position: 1
---

# Views management new design and usage
This document explains how use the views in a feature and how the different components work.

## Activating views in your feature
If your feature has been created with the BIA Toolkit, you should have this section in the routing of the module of your feature that create a route to save a new view or modify an existing one:

```typescript
      {
        path: 'view',
        data: {
          featureConfiguration: myFeatureCRUDConfiguration,
          featureServiceType: MyFeatureService,
          leftWidth: 60,
        },
        loadChildren: () =>
          import('../../shared/bia-shared/view.module').then(m => m.ViewModule),
      },
```

Your feature should also use the **DynamicLayoutComponent** in the routing:

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

If you want to activate the views feature you need to have this part in your module and also set useView to true in your myFeatureCRUDConfiguration object.

This will show the views list box in your index.component.

## Creating a new view
To create a new view, you will have to click on the first (save) icon to the right of the list box of the views.
Clicking this will open a split page view of a form to save informations on a view.

You can continue to modify your table until you're satisfied with the result (adding filter, showing/hiding columns, sorting different columns, changing the number of element per page, etc.). 
If you have the permissions to create a team view, you will have the option to select the type of view (personal or team), and if you chose team, you will have the option to select on which teams to affect this view (only if you have the permission on more team than the current one).
Change the name of the view to fit your need and then click the "Save as new view" button.

This will create a new view that you can now select in the list box of the views.

## Editing an existing view
To edit a view, first select it in the list box of the views, then click on the save icon.
Modify your table until you're satisfied with the result (adding filter, showing/hiding columns, sorting different columns, changing the number of element per page, etc.).

If the selected view is a team view, you need the permission to edit team view to be able to save these modifications. If not, you can still save as a new personal view with the "Save as new view".

When you're done, click "Edit the selected view" button. The view will be replaced by the current state of the table.

If the Default View (or another system view) is selected in the list box, your only option will be to create a new view with the "Save as new view" button.

## Set a view as a default view
If you want a view to be the default view each time you connect to the application, you can set it to default by selecting the view in the list box and then click the second (star) button to the right of the list box of views. This should replace your default view by the selected one.
You can also unset the default view by clicking the same button when the default view is selected. This will set the default view to the system view named "Default View".

## Reset current modification on a view
After selecting a view, you can still change sort, filters, displayed columns, etc.
This will add a * at the left of the view in the list box indicating that the current display is not the saved display for that view. If you want to return to the saved view and cancel your modification, you can click on the third (rotating arrows) icon. This will reload the view as saved.

## Manage views
The fourth (gear) icon opens a popup listing all your views.
In the first part, you will see all your views: personal and team views. You will be able to change the default view but also delete a personal view in this part.

In the second part, you will see the team views that you are allowed to manage across all teams of the application.
This will allow yourself to link a team that is present on another team to your current team, unlink from your current team a view affected to the current team and one or more other teams, or delete a team view that is only affected to your current team.

You can also set the default team view in that second part.
Default team view means that if no personal view is selected by a user, this team view will be the default view for that user.