---
sidebar_position: 1
---

# Modify embedded objects while creating or modifying an object
## What are the advantages of allowing embedded objects modifications in the object edition screen ?
By including the modification of embedded objects in the object modification or creation, you make the user experience better by reducing the number of screens to navigate to and the number of clicks needed to fully create your object.

Example : When I create a plane, I want to create the associated engines.

If I don't allow the creation of the engines in the same view :
1) User creates plane via plane-new screen
2) User then select the plane he just created
3) User then click on Engines button
4) User then can create engines for the plane

If you allow the creation of engines in the same view :
1) User creates plane via plane-new
2) User creates engines via the same screen and just validate plane and engines in one validation click

You can see an example in BIA Demo - Examples - Planes (Specific)

### Warning
Be sure to deactivate the calc mode in your base item table since you can't add embedded items in the datatable.
If you want to keep the calcmode make sure to load previous values of the embedded items array before updating.

## How to implement it ?
### Add embedded items to DTO or create a second DTO item

You might want to have two types of your object : 
- one type for display in DataTable, containing only the properties that you want to show in the table
- one type for consultation, modification or creation of single item
  
Getting only the needed properties for your datatable can make the performance better, especially for Datatable with a lot of items to display.
If you want to keep a single DTO for both datatable and single item read the **Single DTO** chapter and if you want to split DTO read the **Split DTO** chapter.

### Single DTO

#### Angular
In your Angular project, follow the following steps while replacing "myItem" by your object name and "myEmbeddedItem" by the name of your embedded object (example: myItem = plane, myEmbeddedItem = engine). Use a case sensitive replace to make sure to keep the first letter in lower or upper case :
1) Add "MyEmbeddedItems : MyEmbeddedItem[]" in angular DTO (and create MyEmbeddedItem interface if it does not exist).
2) Add 
```typescript
       Object.assign(new BiaFieldConfig('myEmbeddedItems', 'myItem.myEmbeddedItems'), {
            specificOutput: true,
            specificInput: true,
            type: PropType.ManyToMany,
        }),
```
to your ItemFieldsConfiguration
3) create a table component for your embedded item and add it in your feature module
```typescript
@Component({
  selector: 'app-my-embedded-item-table',
  templateUrl:
    '/src/app/shared/bia-shared/components/table/bia-calc-table/bia-calc-table.component.html',
  styleUrls: [
    '/src/app/shared/bia-shared/components/table/bia-calc-table/bia-calc-table.component.scss',
  ],
})
export class MyEmbeddedItemTableComponent extends CrudItemTableComponent<MyEmbeddedItem> {
  constructor(
    public formBuilder: UntypedFormBuilder,
    public authService: AuthService,
    public biaMessageService: BiaMessageService,
    public translateService: TranslateService
  ) {
    super(formBuilder, authService, biaMessageService, translateService);
  }
}
```
4) create the configuration file pour the embedded item if it does not exist :
```typescript
export const myEmbeddedItemCRUDConfiguration: CrudConfig = new CrudConfig({
  // IMPORTANT: this key should be unique in all the application.
  featureName: 'myEmbeddedItems',
  fieldsConfig: myEmbeddedItemFieldsConfiguration,
});
```
5) create an html template for your component form (MyItemFormComponent) that will contains the specific part of the embedded items
6) in that html file, add the specific part :
```html
<bia-form
  [element]="crudItem"
  [fields]="fields"
  [dictOptionDtos]="dictOptionDtos"
  (save)="onSave($event)"
  (cancel)="onCancel()">
  <ng-template pTemplate="specificInput" let-field="field" let-form="form">
    <ng-container *ngIf="field.field == 'myEmbeddedItems'">
      <bia-table-header
        [headerTitle]="field.header | translate"
        [canAdd]="false"
        [canDelete]="true"
        (delete)="onDeleteMyEmbeddedItems()"
        [selectedElements]="selectedMyEmbeddedItems"></bia-table-header>
      <span class="p-float-label">
        <app-my-embedded-item-table
          [elements]="displayedMyEmbeddedItems()"
          [configuration]="myEmbeddedItemCrudConfig"
          [columnToDisplays]="myEmbeddedItemColumnsToDisplay"
          [dictOptionDtos]="[]"
          [totalRecord]="crudItem?.myEmbeddedItems?.length ?? 0"
          [paginator]="false"
          [showColSearch]="false"
          [canEdit]="true"
          [canAdd]="true"
          [canSelectElement]="true"
          [loading]="false"
          (selectedElementsChanged)="onSelectedMyEmbeddedItemsChanged($event)"
          (save)="onMyEmbeddedItemSave($event)" />
      </span>
    </ng-container>
  </ng-template>
</bia-form>
```
7) Create the properties and functions to manage your embedded items in MyItemFormComponent :
```typescript
export class MyItemFormComponent extends CrudItemFormComponent<MyItem> {
  @ViewChild(MyEmbeddedItemTableComponent) myEmbeddedItemTableComponent: MyEmbeddedItemTableComponent;

  myEmbeddedItemCrudConfig: BiaFieldsConfig = myEmbeddedItemCRUDConfiguration.fieldsConfig;
  myEmbeddedItemColumnsToDisplay: KeyValuePair[];
  newId: number = CrudHelperService.NewIdStartingValue;
  displayedMyEmbeddedItems: WritableSignal<MyEmbeddedItem[]> = signal([]);

  constructor() {
    super();
    this.myEmbeddedItemColumnsToDisplay = this.myEmbeddedItemCrudConfig.columns
      .filter(col => !col.isHideByDefault)
      .map(col => <KeyValuePair>{ key: col.field, value: col.header });
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes.crudItem) {
      this.setDisplayedMyEmbeddedItems();
    }
  }

  setDisplayedMyEmbeddedItems() {
    this.displayedMyEmbeddedItems.update(() =>
      this.crudItem?.myEmbeddedItems
        ? this.crudItem.myEmbeddedItems.filter(e => e.dtoState !== DtoState.Deleted)
        : []
    );
  }

  onSelectedMyEmbeddedItemsChanged(selectedMyEmbeddedItems: MyEmbeddedItem[]) {
    this.selectedMyEmbeddedItems = selectedMyEmbeddedItems;
  }

  onMyEmbeddedItemSave(myEmbeddedItem: MyEmbeddedItem) {
    this.crudItem.myEmbeddedItems ??= [];
    this.newId = BiaCrudHelperService.onEmbeddedItemSave(
      myEmbeddedItem,
      this.crudItem.myEmbeddedItems,
      this.newId
    );
    this.setDisplayedMyEmbeddedItems();
    this.myEmbeddedItemTableComponent.resetEditableRow();
  }

  onDeleteMyEmbeddedItems() {
    this.selectedMyEmbeddedItems.forEach(e => (e.dtoState = DtoState.Deleted));
    this.setDisplayedMyEmbeddedItems();
  }

   onSave(crudItem: MyItem) {
    if (this.myEmbeddedItemTableComponent.isInEditing) {
      setTimeout(() => {
        this.onSave(crudItem);
      }, 100);
    } else {
      crudItem.myEmbeddedItems = this.crudItem?.myEmbeddedItems ?? [];
      this.save.emit(crudItem);
    }
  }
}
```
8) In MyItemService, add a reset of the new items id (that are negative for display purpose) before calling store "create" and "update" actions and a clone of MyItem on the selector :
```typescript
  public crudItem$: Observable<MyItem> = this.store
    .select(FeatureMyItemsStore.getCurrentMyItem)
    .pipe(map(myItem => clone(myItem)));

  public create(crudItem: MyItem) {
    this.resetNewItemsIds(crudItem.myEmbeddedItems);
    (crudItem.siteId = this.getParentIds()[0]),
      this.store.dispatch(FeatureMyItemsActions.create({ myItem: crudItem }));
  }

  public update(crudItem: MyItem) {
    this.resetNewItemsIds(crudItem.myEmbeddedItems);
    this.store.dispatch(FeatureMyItemsActions.update({ myItem: crudItem }));
  }
```

You're done with the Angular part

### .Net
In your .Net projects, follow the following steps while replacing "myItem" by your object name and "myEmbeddedItem" by the name of your embedded object (example: myItem = plane, myEmbeddedItem = engine). Use a case sensitive replace to make sure to keep the first letter in lower or upper case :

1) In the entity model of MyItem, add a collection of MyEmbeddedItem :
```csharp
        /// <summary>
        /// Gets or sets the list of myEmbeddedItems for myItem.
        /// </summary>
        public ICollection<MyEmbeddedItem> MyEmbeddedItems { get; set; }
```
2) In the model builder of MyItem, initialize the collection rules :
In CreateMyItemModel function :
```csharp
            modelBuilder.Entity<MyItem>()
                .HasMany(x => x.MyEmbeddedItems)
                .WithOne()
                .HasForeignKey(x => x.MyItemId);
```
In CreateMyEmbeddedItemModel function :
```csharp
            modelBuilder.Entity<MyEmbeddedItem>()
                .HasOne(x => x.MyItem)
                .WithMany(x => x.MyEmbeddedItems)
                .OnDelete(DeleteBehavior.ClientCascade);
```
3) In the mapper, define how to transform the list on Embedded items entity to Dto and the embedded items dto to entity (using helper method MapEmbeddedItemToEntityCollection). You will need to inject the mapper of MyEmbeddedItem (MyEmbeddedItemMapper) :
```csharp
    public override void DtoToEntity(MyItemDto dto, MyItem entity)
    {
        // Begin properties mapping
        // ...
        // End properties mapping
        entity.MyEmbeddedItems ??= [];
        MapEmbeddedItemToEntityCollection(dto.MyEmbeddedItems, entity.MyEmbeddedItems, this.myEmbeddedItemMapper);
    }

    public override Expression<Func<MyItem, MyItemDto>> EntityToDto() {
        return entity => new MyItemDto
        {
            // Begin properties mapping
            // ...
            // End properties mapping
            MyEmbeddedItems = entity.MyEmbeddedItems.Select(myEmbeddedItem => new MyEmbeddedItemDto
            {
                Id = MyEmbeddedItem.Id,
                // Begin MyEmbeddedItem properties mapping
                // ...
                // End MyEmbeddedItem properties mapping
                MyItemId = myEmbeddedItem.MyItemId,
            }).OrderBy(x => x.MySortingProperty).ToList(),
        };
    }

    public override Expression<Func<MyItem, object>>[] IncludesForUpdate()
    {
        return [/* All the previous includes, */ x => x.MyEmbeddedItems];
    }
```

You're done !

### Split DTO
Terms to replace in your project :
- MyListItem = Type of item for the list (getAll, datatable, etc.). It will usually be the item you already are using that doesn't have a property for your embedded items.
- MySingleItem = Type of item for the single manipulation (update, create, get).
- MyEmbeddedItem = Type of the objects you want to create, delete, update while updating or creating a MySingleItem.
- myItem = generic name of the object (used for property name).

#### Angular

In your Angular project, follow the following steps and use a case sensitive replace to make sure to keep the first letter in lower or upper case :
1) Create an interface MySingleItem extending MyListItem. This will be the class used in every view and functions manipulating a single element.
```typescript
export interface MySingleItem extends MyListItem {
  myEmbeddedItems: MyEmbeddedItem[];
}
```
2) Create a config for the fields of MySingleItem reusing the config of MyListItem. Make sure you have a translation available for myItem.myEmbeddedItems :
```typescript
export const mySingleItemFieldsConfiguration: BiaFieldsConfig = {
  columns: [
    ...myListItemFieldsConfiguration.columns,
    Object.assign(new BiaFieldConfig('myEmbeddedItems', 'myItem.myEmbeddedItems'), {
        specificOutput: true,
        specificInput: true,
        type: PropType.ManyToMany,
    }),
  ],
};
```
3) Modify the type in these class from MyListItem to MySingleItem
- in MyItemFormComponent : now extends CrudItemFormComponent&lt;MySingleItem>
- in MyItemDas : now extends AbstractDas&lt;MyListItem, MySingleItem>
- in MyItemService : 
  - now extends CrudItemService&lt;MyListItem, MySingleItem>
  - crudItem$ return value -> Observable&lt;MySingleItem>
  - create function parameter -> crudItem: MySingleItem
  - update function parameter -> crudItem: MySingleItem
  - replace this._currentCrudItem = &lt;MyListItem>{}; by this._currentCrudItem = &lt;MySingleItem>{};
- in actions FeatureMyItemsActions : in create, update and loadSuccess, replace MyListItem by MySingleItem
- in the reducer file :  replace currentMyItem type in declaration and initialization by MySingleItem
- in MyItemEditComponent : now extends CrudItemEditComponent&lt;MySingleItem>
- in MyItemNewComponent : now extends CrudItemNewComponent&lt;MySingleItem>
4) create a table component for your embedded item and add it in your feature module
```typescript
@Component({
  selector: 'app-my-embedded-item-table',
  templateUrl:
    '/src/app/shared/bia-shared/components/table/bia-calc-table/bia-calc-table.component.html',
  styleUrls: [
    '/src/app/shared/bia-shared/components/table/bia-calc-table/bia-calc-table.component.scss',
  ],
})
export class MyEmbeddedItemTableComponent extends CrudItemTableComponent<MyEmbeddedItem> {
  constructor(
    public formBuilder: UntypedFormBuilder,
    public authService: AuthService,
    public biaMessageService: BiaMessageService,
    public translateService: TranslateService
  ) {
    super(formBuilder, authService, biaMessageService, translateService);
  }
}
```
5) create the configuration file pour the embedded item if it does not exist :
```typescript
export const myEmbeddedItemCRUDConfiguration: CrudConfig = new CrudConfig({
  // IMPORTANT: this key should be unique in all the application.
  featureName: 'myEmbeddedItems',
  fieldsConfig: myEmbeddedItemFieldsConfiguration,
});
```
6) create an html template for your component form (MyItemFormComponent) that will contains the specific part of the embedded items
7) in that html file, add the specific part :
```html
<bia-form
  [element]="crudItem"
  [fields]="fields"
  [dictOptionDtos]="dictOptionDtos"
  (save)="onSave($event)"
  (cancel)="onCancel()">
  <ng-template pTemplate="specificInput" let-field="field" let-form="form">
    <ng-container *ngIf="field.field == 'myEmbeddedItems'">
      <bia-table-header
        [headerTitle]="field.header | translate"
        [canAdd]="false"
        [canDelete]="true"
        (delete)="onDeleteMyEmbeddedItems()"
        [selectedElements]="selectedMyEmbeddedItems"></bia-table-header>
      <span class="p-float-label">
        <app-my-embedded-item-table
          [elements]="displayedMyEmbeddedItems"
          [configuration]="myEmbeddedItemCrudConfig"
          [dictOptionDtos]="[]"
          [totalRecord]="crudItem?.myEmbeddedItems?.length ?? 0"
          [paginator]="false"
          [showColSearch]="false"
          [canEdit]="true"
          [canAdd]="true"
          [canSelectElement]="true"
          [loading]="false"
          (selectedElementsChanged)="onSelectedMyEmbeddedItemsChanged($event)"
          (save)="onMyEmbeddedItemSave($event)" />
      </span>
    </ng-container>
  </ng-template>
</bia-form>
```
8) Create the properties and functions to manage your embedded items in MyItemFormComponent :
```typescript
export class MyItemFormComponent extends CrudItemFormComponent<MySingleItem> {
  myEmbeddedItemCrudConfig: BiaFieldsConfig = myEmbeddedItemCRUDConfiguration.fieldsConfig;
  newId: number = CrudHelperService.NewIdStartingValue;
  selectedMyEmbeddedItems: MyEmbeddedItem[] = [];

  get displayedMyEmbeddedItems(): MyEmbeddedItem[] {
    return this.crudItem.myEmbeddedItems
      ? this.crudItem.myEmbeddedItems.filter(e => e.dtoState !== DtoState.Deleted)
      : [];
  }

  onSelectedMyEmbeddedItemsChanged(selectedMyEmbeddedItems: MyEmbeddedItem[]) {
    this.selectedMyEmbeddedItems = selectedMyEmbeddedItems;
  }

  onMyEmbeddedItemSave(myEmbeddedItem: MyEmbeddedItem) {
    this.crudItem.myEmbeddedItems ??= [];
    this.newId = BiaCrudHelperService.onEmbeddedItemSave(
      myEmbeddedItem,
      this.crudItem.myEmbeddedItems,
      this.newId
    );
  }

  onDeleteMyEmbeddedItems() {
    this.selectedMyEmbeddedItems.forEach(e => (e.dtoState = DtoState.Deleted));
  }
}
```
9) In MyItemService, add a reset of the new items id (that are negative for display purpose) before calling store "create" and "update" actions and a clone of MyItem on the selector :
```typescript
  public crudItem$: Observable<MySingleItem> = this.store
    .select(FeatureMyItemsStore.getCurrentMyItem)
    .pipe(map(myItem => clone(myItem)));

  public create(crudItem: MySingleItem) {
    this.resetNewItemsIds(crudItem.myEmbeddedItems);
    (crudItem.siteId = this.getParentIds()[0]),
      this.store.dispatch(FeatureMyItemsActions.create({ myItem: crudItem }));
  }

  public update(crudItem: MySingleItem) {
    this.resetNewItemsIds(crudItem.myEmbeddedItems);
    this.store.dispatch(FeatureMyItemsActions.update({ myItem: crudItem }));
  }
```

### .Net
In your .Net projects, follow the following steps while replacing "myItem" by your object name and "myEmbeddedItem" by the name of your embedded object (example: myItem = plane, myEmbeddedItem = engine). Use a case sensitive replace to make sure to keep the first letter in lower or upper case :

1) In the entity model of MyItem, add a collection of MyEmbeddedItem :
```csharp
        /// <summary>
        /// Gets or sets the list of myEmbeddedItems for myItem.
        /// </summary>
        public ICollection<MyEmbeddedItem> MyEmbeddedItems { get; set; }
```
2) In the model builder of MyItem, initialize the collection rules :
In CreateMyItemModel function :
```csharp
            modelBuilder.Entity<MyItem>()
                .HasMany(x => x.MyEmbeddedItems)
                .WithOne()
                .HasForeignKey(x => x.MyItemId);
```
In CreateMyEmbeddedItemModel function :
```csharp
            modelBuilder.Entity<MyEmbeddedItem>()
                .HasOne(x => x.MyItem)
                .WithMany(x => x.MyEmbeddedItems)
                .OnDelete(DeleteBehavior.ClientCascade);
```
3) Define MySingleItemDto by inheriting MyListItemDto
```csharp
    /// <summary>
    /// The DTO used to represent a complete MyItem.
    /// </summary>
    public class MySingleItemDto : MyListItemDto
    {
        /// <summary>
        /// Gets or sets the list of connecting airports.
        /// </summary>
        [BiaDtoField(ItemType = "MyEmbeddedItem", Required = true)]
        public ICollection<MyEmbeddedItemDto> MyEmbeddedItems { get; set; }
    }
```
4) Create a new mapper for MySingleItemDto and MyItem. It can use the existing mapper for MyListItemDto and MyItem as reference or by injecting it. In the mapper, define how to transform the list on Embedded items entity to Dto and the embedded items dto to entity (using helper method MapEmbeddedItemToEntityCollection). You will need to inject the mapper of MyEmbeddedItem (MyEmbeddedItemMapper) :
```csharp
    public override void DtoToEntity(MyItemDto dto, MyItem entity)
    {
        // Begin properties mapping
        // ...
        // End properties mapping
        // OR 
        this.myListItemMapper.DtoToEntity(dto, entity);
        // THEN
        entity.MyEmbeddedItems ??= [];
        MapEmbeddedItemToEntityCollection(dto.MyEmbeddedItems, entity.MyEmbeddedItems, this.myEmbeddedItemMapper);
    }

    public override Expression<Func<MyItem, MyItemDto>> EntityToDto() {
        return entity => new MyItemDto
        {
            // Begin properties mapping
            // ...
            // End properties mapping
            MyEmbeddedItems = entity.MyEmbeddedItems.Select(myEmbeddedItem => new MyEmbeddedItemDto
            {
                Id = MyEmbeddedItem.Id,
                // Begin MyEmbeddedItem properties mapping
                // ...
                // End MyEmbeddedItem properties mapping
                MyItemId = myEmbeddedItem.MyItemId,
            }).OrderBy(x => x.MySortingProperty).ToList(),
        };
    }

    public override Expression<Func<MyItem, object>>[] IncludesForUpdate()
    {
        return [/* All the previous includes, */ x => x.MyEmbeddedItems];
    }
```
5) Change MyItemAppService by inheriting CrudAppServiceListAndItemBase and IMyItemAppService by implementing ICrudAppServiceListAndItemBase :
```csharp
    public class MyItemAppService :
        CrudAppServiceListAndItemBase<MySingleItemDto, MyListItemDto, Plane, int, PagingFilterFormatDto, MySingleItemMapper, MyListItemMapper>,
        IMyItemAppService
    {
    }
```
```csharp
    public interface IMyItemAppService : ICrudAppServiceListAndItemBase<MySingleItemDto, MyListItemDto, MyItem, int, PagingFilterFormatDto>
    {
    }
```
6) Change controller types if needed.

You're done !