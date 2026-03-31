---
sidebar_position: 1
---

# Query Model Mapper

:::info
This document explains what `QueryModelMapper` is, why to use it and how to integrate it into a project that uses the BIA Framework.
:::

## Overview

`BiaBaseQueryModelMapper<TQueryModel, TDto, TDtoListItem, TEntity, TKey, TMapper>` is a base mapper class designed to separate the formatting/shape of data returned by database queries from the standard entity -> DTO mapping implemented in `BiaBaseMapper`. It delegates expression/field definitions to an inner `TMapper` while letting you implement custom formatting logic for query models (projection results, joined queries, aggregated values, pre-formatted strings, etc.).

- `BiaBaseQueryModelMapper` itself extends `BiaBaseMapper<TQueryModel, TEntity, TKey>` so it can be used where a mapper for the query model is required.
- It holds an inner `TMapper` (a `BiaBaseMapper<TDto, TEntity, TKey>`) and exposes its `ExpressionCollection`. 
- You implement `QueryModelToDto` and `QueryModelToDtoListItem` to translate query results into final DTO(s).

## Why use it

Use `BiaBaseQueryModelMapper` when:
- Your query needs to returns a projection or an intermediate model (a `TQueryModel`) rather than the full `TEntity` for performance concerns.
- You need to format or compute DTO fields from raw query columns (for example localized formatted dates, computed labels, concatenated strings, translation keys or aggregated values)

## How it works

- Repository executes a query that projects into `TQueryModel` using expressions. The `ExpressionCollection` used to build the filters projection is provided by the inner `TMapper`.
- The repository returns `TQueryModel` instances (often lightweight DTO-like intermediate objects).
- `BiaBaseQueryModelMapper` implementation converts these `TQueryModel` instances into the final `TDto` or `TDtoListItem` using `QueryModelToDto` and `QueryModelsToDtoListItems`.

## Implementation steps 

Below are minimal working examples showing how to define entity, DTOs, mappers and how to use a `QueryModelMapper`

### 1) Entity

```csharp title="MyEntity.cs"
public class MyEntity : IEntity<int>
{
    public int Id { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public DateTime CreatedAt { get; set; }
    public RelatedEntity Related { get; set; }
    public int RelatedId { get; set; }
    public ICollection<JoinedEntity> JoinedEntities { get; set; }
    public ICollection<MyEntityJoinedEntity> MyEntityJoinedEntities { get; set; }
}
```

### 2) DTOs

```csharp title="MyEntityDto.cs"
public class MyEntityDto : BaseDto<int>
{
    public string FullName { get; set; }
    public string FormattedDate { get; set; }
    public OptionDto Related { get; set; }
    public ICollection<OptionDto> Joined { get; set; }
}
```

```csharp title="MyEntityDtoListItem.cs"
public class MyEntityDtoListItem : BaseDto<int>
{
    public string FullName { get; set; }
    public string FormattedDate { get; set; }
    public string Related { get; set; }
    public string Joined { get; set; }
}
```

### 3) QueryModel
:::info
Should be created into `MyCompany.MyProject.Domain.MyDomain.QueryModels` namespace
:::

Commonly, the query model will be much or less the same as the entity. It must inherited at least from `BaseDto<TKey>`.  
Keep only the required navigation properties if needed.

```csharp title="MyEntityQueryModel.cs"
public class MyEntityQueryModel : BaseDto<int>
{
    public int Id { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public DateTime CreatedAt { get; set; }
    public RelatedEntity Related { get; set; }
    public ICollection<JoinedEntity> JoinedEntities { get; set; }
}
```

:::tip
Don't simply add your entity model as single property into your query model, it will be more efficient to have the bunch of required properties to retrieve from database instead of the complete properties of your entity.
:::

### 4) QueryModelMapper
:::info
Should be created into `MyCompany.MyProject.Domain.MyDomain.QueryModels` namespace
:::

Create your own query model mapper by inheriting of `BiaBaseQueryModelMapper`.  
You must implement the abstract methods `QueryModelToDto` and `QueryModelToDtoListItem`, and overrides the `EntityToDto` method.

:::tip
- Keep `EntityToDto` for server-side projections that can be translated to SQL
- Use `QueryModelToDto` and `QueryModelToDtoListItem` to run .NET-only formatting after projection.
:::

```csharp title="MyEntityQueryModelMapper.cs"
public class MyEntityQueryModelMapper : BiaBaseQueryModelMapper<MyEntityQueryModel, MyEntityDto, MyEntityDtoListItem, MyEntity, int, MyEntityMapper>
{
    public MyEntityQueryModelMapper(MyEntityMapper mapper)
        : base(mapper)
    {
    }

    public override Expression<Func<MyEntity, MyEntityQueryModel>> EntityToDto()
    {
        return entity => new MyEntityQueryModel
        {
            Id = entity.Id,
            FirstName = entity.FirstName,
            LastName = entity.LastName,
            CreatedAt = entity.CreatedAt,
            Related = entity.Related,
            JoinedEntities = entity.JoinedEntities
        };
    }

    public override MyEntityDto QueryModelToDto(MyEntityQueryModel queryModel)
    {
        return new MyEntityDto
        {
            Id = queryModel.Id,
            FullName = string.Concat(queryModel.FirstName, " ", queryModel.LastName),
            FormattedDate = queryModel.CreatedAt.ToString("yyyy-MM-dd"),
            Related = queryModel.Related != null ? new OptionDto { Id = queryModel.Related.Id, Display = queryModel.Related.Inner.Name } : null,
            Joined = queryModel.JoinedEntities.Select(x => { new OptionDto { Id = x.Id, Display = x.Value } });
        };
    }

    protected override MyEntityDtoListItem QueryModelToDtoListItem(MyEntityQueryModel queryModel)
    {
        return new MyEntityDtoListItem
        {
            Id = queryModel.Id,
            FullName = string.Concat(queryModel.FirstName, " ", queryModel.LastName),
            FormattedDate = queryModel.CreatedAt.ToString("yyyy-MM-dd"),
            Related = queryModel.Related?.Inner?.Name ?? string.empty;
            Joined = string.Join(", ", query.Model.JoinedEntities.Selec(x => x.Value))
        };
    }
}
```

:::tip
If `TDto` and `TDtoListItem` are of same type, simply return the result of `QueryModelToDto` inside `QueryModelToDtoListItem` override.
```csharp title="MyEntityQueryModelMapper.cs"
public class MyEntityQueryModelMapper : BiaBaseQueryModelMapper<MyEntityQueryModel, MyEntityDto, MyEntityDto, MyEntity, int, MyEntityMapper>
{
    public MyEntityQueryModelMapper(MyEntityMapper mapper)
        : base(mapper)
    {
    }

    public override Expression<Func<MyEntity, MyEntityQueryModel>> EntityToDto()
    {
        return entity => new MyEntityQueryModel
        {
            Id = entity.Id,
            FirstName = entity.FirstName,
            LastName = entity.LastName,
            CreatedAt = entity.CreatedAt,
            Related = entity.Related,
            JoinedEntities = entity.JoinedEntities
        };
    }

    public override MyEntityDto QueryModelToDto(MyEntityQueryModel queryModel)
    {
        return new MyEntityDto
        {
            Id = queryModel.Id,
            FullName = string.Concat(queryModel.FirstName, " ", queryModel.LastName),
            FormattedDate = queryModel.CreatedAt.ToString("yyyy-MM-dd"),
            Related = queryModel.Related != null ? new OptionDto { Id = queryModel.Related.Id, Display = queryModel.Related.Inner.Name } : null,
            Joined = queryModel.JoinedEntities.Select(x => { new OptionDto { Id = x.Id, Display = x.Value } });
        };
    }

    protected override MyEntityDto QueryModelToDtoListItem(MyEntityQueryModel queryModel)
    {
        return this.QueryModelToDto(queryModel);
    }
}
```
:::

### 5) QueryCustomizer

Implements an `IQueryCustomizer<TEntity>` to allow your application service to configure includes or other query modifications per request context. When using query-model mappers that rely on related navigation data, you must set the repository's `QueryCustomizer` in the application service so that includes are applied.

```csharp title="MyEntityQueryCustomizer.cs"
public class MyEntityQueryCustomizer : TQueryCustomizer<MyEntity>, IMyEntityQueryCustomizer
{
    public override IQueryable<MyEntity> CustomizeAfter(IQueryable<MyEntity> objectSet, string queryMode)
    {
        return queryMode switch
        {
            QueryMode.Read or QueryMode.ReadList => objectSet
                .Include(e => e.Related)
                    .ThenInclue(e => e.Inner)
            _ => objectSet,
        };
    }
}
```

:::warning
If your projection or query-model mapping requires navigation properties, register and set the correct `IQueryCustomizer<TEntity>` in the application service. Otherwise Entity Framework may not include the related data and runtime errors or empty collections may occur.  

Add explciit includes only for navigation properties not included into `EntityToDto` of your `QueryModelMapper`.
:::

:::tip
Map which `queryMode` values your repository and application services use. Use distinct `queryMode` constants for lightweight reads vs reads that require navigation includes (for example, distinct includes for `Read` and `ReadList`). This keeps queries efficient and explicit.
:::

### 6) Application Service

```csharp title="MyEntityAppService.cs"
public class MyEntityAppService : CrudAppServiceListAndItemBase<MyEntityDto, MyEntityDtoListItem, MyEntity, int, PagingFilterFormatDto, MyEntityMapper, MyEntityListMapper>
{
    private readonly MyEntityQueryModelMapper myEntityQueryModelMapper;

    public MyEntityAppService(
        ITGenericRepository<MyEntity, int> repository,
        // Injection of query model mapper and query customizer
        MyEntityQueryModelMapper myEntityQueryModelMapper,
        IMyEntityQueryCustomizer myEntityQueryCustomizer)
        : base(repository)
    {
        this.myEntityQueryModelMapper = myEntityQueryModelMapper;
        // Assign query customizer to the repository
        this.Repository.QueryCustomizer = myEntityQueryCustomizer;
    }

    // ***********************
    // NOTE: overrides the following methods to retrieve your query models first, then convert them to target DTO
    // ***********************

    public override async Task<(IEnumerable<MyEntityDtoListItem> Results, int Total)> GetRangeAsync(...)
    {
        var (results, total) = await this.GetRangeGenericAsync<MyEntityQueryModel, MyEntityQueryModelMapper, PagingFilterFormatDto>(...);
        return (this.myQueryModelMapper.QueryModelsToDtoListItems(results), total);
    }

    public override async Task<IEnumerable<MyEntityDtoListItem>> GetAllAsync(...)
    {
        var result = await this.GetAllGenericAsync<MyEntityQueryModel, MyEntityQueryModelMapper>(...);
        return this.myQueryModelMapper.QueryModelsToDtoListItems(result);
    }

    public override async Task<IEnumerable<MyEntityDtoListItem>> GetAllAsync(...)
    {
        var result = await this.GetAllGenericAsync<MyEntityQueryModel, MyEntityQueryModelMapper>(...);
        return this.myQueryModelMapper.QueryModelsToDtoListItems(result);
    }

    public override async Task<MyEntityDto> GetAsync(...)
    {
        var result = await this.GetGenericAsync<MyEntityQueryModel, MyEntityQueryModelMapper>(...);
        return this.myQueryModelMapper.QueryModelToDto(result);
    }
}
```

:::warning
If you don't override these methods (or otherwise convert `TQueryModel` to DTOs in the service layer), callers will not get the final DTO shape produced by your `QueryModelMapper`.
:::

## Tips

:::tip
Be mindful of the difference between projection expressions (used by EF to generate SQL) and in-memory formatting. Trying to put .NET-only formatting into expression trees can lead to runtime exceptions or poor SQL translation.  
Format heavy or .NET-only fields (localized text, complex date formatting) in `QueryModelToDto` after projection. That avoids forcing expression trees to include non-translatable operations.
:::

:::tip
Returning `TQueryModel` from queries means the DB query can select only the needed columns. Format/compute heavier fields in `QueryModelToDto` in memory after projection, which can be beneficial when formatting cannot be expressed in SQL or when formatting requires .NET APIs.
:::