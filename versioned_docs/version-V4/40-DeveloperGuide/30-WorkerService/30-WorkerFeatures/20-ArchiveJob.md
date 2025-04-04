---
sidebar_position: 1
---

# Archive Job
The archive job is a recurred task created to archive entities from database into flat text on a target directory.

## How it works 
1. Archive job is launched from Hangfire Server throught the Worker Service according to the CRON settings.
2. Each injected implementation of `IArchiveService` related to a specific archivable entity `IEntityArchivable` throught an `ITGenericArchiveRepository` will be runned one per one
3. The items to archive will be selected according to following rules from the related archive service :
   - Entity is fixed
   - Entity has not been already archived **OR** entity has already been archived and last fixed date is superior than archived date
4. The selected items are saved into compressed archive file to the target directory one per one : unique file per item, overwritten. Each copy to the target directory is verified by an integrity comparison of checksum.

## Configuration
### CRON settings
1. In the **DeployDB** project, the CRON settings of the archive job are set into the `appsettings.json` :
``` json title="appsettings.json"
{
  "Tasks": {
    "Archive": {
      "CRON": "0 3 * * *"
    }
  }
}
```
2. In `Program.cs` add the task to the Hangfire service : 
``` csharp title="Program.cs"
namespace TheBIADevCompany.BIADemo.DeployDB
{
    public static class Program
    {
        public static async Task Main(string[] args)
        {
            await new HostBuilder()
                // [...]
                .ConfigureServices((hostingContext, services) =>
                {
                    // [...]

                    services.AddHangfire(config =>
                    {
                        // [...]
                        RecurringJob.AddOrUpdate<ArchiveTask>($"{projectName}.{typeof(ArchiveTask).Name}", t => t.Run(), configuration["Tasks:Archive:CRON"]);
                    });
                })
                // [...]
        }
    }
}
```
3. Run the **DeployDB** to update your Hangfire settings with this configuration and enable archive job.

### Archive job
In the **WorkerService** project, the settings for the archive job are set into the `bianetconfig.json` :
``` json title="bianetconfig.json"
{
  "BiaNet": {
    "WorkerFeatures": {
      "Archive": {
        "IsActive": true,
        "ArchiveEntityConfigurations": [
          {
            "EntityName": "MyEntity",
            "TargetDirectoryPath": "C:\\temp\\archives\\myproject\\myentities"
          }
        ]
      }
    }
  }
}
```
You must set an `ArchiveEntityConfiguration` for each entity to archive.

## Implementation
### Archivable entity
Your entity type to archive must implements the `IEntityArchivable<TKey>` that inherits from `IEntityFixable<TKey>` :
``` csharp title="MyEntity.cs"
public class MyEntity : IEntityArchivable<int>
{
    /// Entity key
    public int Id { get; set; }

    /// [...] Other properties

    /// Indicates weither the entity is fixed or not
    public bool IsFixed { get; set; }

    /// Fixed date
    public DateTime? FixedDate { get; set; }

    /// Indicates weither the entity is archived or not
    public bool IsArchived { get; set; }

    /// Archived date
    public DateTime? ArchivedDate { get; set; }
}
```

Then, create a new migration to update your table in database :
1. `add-migration -context "datacontext" AddArchivablePropertiesTableMyEntity`
2. `update-database -context "datacontext"` 

### Archive repository
#### Default
The BIA Frawmeork will automatically associate the corresponding implementation `TGenericArchiveRepository<TEntity, TKey>` of all interfaces `ITGenericArchiveRepository<TEntity, TKey>` when requested by injection in the archive service (see [next chapter](#archive-service)).

So, you don't have to implement your own archive repository for your entity !  

Here are the description of the interface and the implementation of the default archive repository : 
``` csharp title="ITGenericArchiveRepository.cs"
namespace BIA.Net.Core.Domain.RepoContract
{
    /// <summary>
    /// Interface for generic archive repository of an entity.
    /// </summary>
    /// <typeparam name="TEntity">Entity type.</typeparam>
    /// <typeparam name="TKey">Entity key type.</typeparam>
    public interface ITGenericArchiveRepository<TEntity, TKey>
        where TEntity : class, IEntityArchivable<TKey>
    {
        /// <summary>
        /// Return the items to archive according to the filter rule.
        /// </summary>
        /// <param name="rule">Filter rule.</param>
        /// <returns><see cref="Task{IReadOnlyList{TEntity}}"/>.</returns>
        Task<IReadOnlyList<TEntity>> GetAllAsync(Expression<Func<TEntity, bool>> rule);

        /// <summary>
        /// Update archive state of an entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <returns><see cref="Task"/>.</returns>
        Task SetAsArchivedAsync(TEntity entity);
    }
}
```

``` csharp title="TGenericArchiveRepository.cs"
namespace BIA.Net.Core.Infrastructure.Data.Repositories
{
    /// <summary>
    /// Generich archive repository of an entity.
    /// </summary>
    /// <typeparam name="TEntity">The entity type.</typeparam>
    /// <typeparam name="TKey">The entity key type.</typeparam>
    public class TGenericArchiveRepository<TEntity, TKey> : ITGenericArchiveRepository<TEntity, TKey>
        where TEntity : class, IEntityArchivable<TKey>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="TGenericArchiveRepository{TEntity, TKey}"/> class.
        /// </summary>
        /// <param name="context">The <see cref="IQueryableUnitOfWork"/> context.</param>
        public TGenericArchiveRepository(IQueryableUnitOfWork context);

        /// <summary>
        /// The context.
        /// </summary>
        protected IQueryableUnitOfWork Context { get; }

        /// <inheritdoc/>
        public virtual async Task<IReadOnlyList<TEntity>> GetAllAsync(Expression<Func<TEntity, bool>> rule);

        /// <inheritdoc/>
        public virtual async Task SetAsArchivedAsync(TEntity entity);

        /// <summary>
        /// Return all the entities with automatic includes.
        /// </summary>
        /// <returns><see cref="IQueryable{TEntity}"/>.</returns>
        protected virtual IQueryable<TEntity> GetAllQuery();
    }
}
```
**NOTES :** 
- the `GetAllAsync()` method will filter with the given rule on the query returned by the `GetAllQuery()` method 
- the `GetAllQuery()` method returns all the entities with automatic includes :
  - includes all navigation properties at root level of the entity
  - includes recursively all the navigation properties with cascade delete relationship to the entity
  - use `AsSplitQuery()` ([documentation](https://learn.microsoft.com/en-us/ef/core/querying/single-split-queries))
- the method `SetAsArchivedAsync()` will set the `IsArchived` property of the entity to `true` and set the `ArchivedDate` to current date time UTC and commit immediatly
  
#### Custom
If you need to customize the default repository (to change the includes of `GetAllQuery()` method for example) :
1. Create your interface that will inherit from `ITGenericArchiveRepository<TEntity, TKey>` in **MyCompany.MyProject.Domain.RepoContract** namespace :
``` csharp title="IMyEntityArchiveRepository.cs"
namespace MyCompany.MyProject.Domain.RepoContract
{
    /// <summary>
    /// Interface for <see cref="MyEntity"/> archive repository.
    /// </summary>
    public interface IMyEntityArchiveRepository : ITGenericArchiveRepository<MyEntity, int>
    {
    }
}
```
2. Create your implementation that will inherit from `TGenericArchiveRepository<TEntity, TKey>` in **MyCompany.MyProject.Infrastructure.Data.Repositories.ArchiveRepositories** namespace :
``` csharp title="MyEntityArchiveRepository.cs"
namespace MyCompany.MyProject.Infrastructure.Data.Repositories.ArchiveRepositories
{
    /// <summary>
    /// Archive repository for <see cref="MyEntity"/> entity.
    /// </summary>
    public class MyEntityArchiveRepository : TGenericArchiveRepository<MyEntity, int>, IMyEntityArchiveRepository
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="MyEntityArchiveRepository"/> class.
        /// </summary>
        /// <param name="dataContext">The <see cref="IQueryableUnitOfWork"/> context.</param>
        public MyEntityArchiveRepository(IQueryableUnitOfWork dataContext)
            : base(dataContext)
        {
        }
    }
}
```

### Archive service
#### Principles
The archive service associated to an entity to archive must inherits from `ArchiveServiceBase` :
``` csharp title="ArchiveServiceBase.cs"
namespace BIA.Net.Core.Application.Archive
{
    /// <summary>
    /// The base service for the archive services of an entity.
    /// </summary>
    /// <typeparam name="TEntity">The entity type.</typeparam>
    /// <typeparam name="TKey">The entity key type.</typeparam>
    public abstract class ArchiveServiceBase<TEntity, TKey> : IArchiveService
        where TEntity : class, IEntityArchivable<TKey>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="ArchiveServiceBase{TEntity, TKey}"/> class.
        /// </summary>
        /// <param name="configuration">The configuration.</param>
        /// <param name="archiveRepository">The <see cref="ITGenericArchiveRepository{TEntity, TKey}"/> archive repository.</param>
        /// <param name="logger">The logger.</param>
        protected ArchiveServiceBase(IConfiguration configuration, ITGenericArchiveRepository<TEntity, TKey> archiveRepository, ILogger logger);

        /// <summary>
        /// The entity archive configuration.
        /// </summary>
        protected ArchiveEntityConfiguration ArchiveEntityConfiguration { get; }

        /// <summary>
        /// The entity archive repository.
        /// </summary>
        protected ITGenericArchiveRepository<TEntity, TKey> ArchiveRepository { get; }

        /// <summary>
        /// The logger.
        /// </summary>
        protected ILogger Logger { get; }

        /// <summary>
        /// Run the service.
        /// </summary>
        /// <returns><see cref="Task"/>.</returns>
        public virtual async Task RunAsync();

        /// <summary>
        /// Retrive the archive file name template for an entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <returns><see cref="string"/>.</returns>
        protected abstract string GetArchiveNameTemplate(TEntity entity);

        /// <summary>
        /// The rule to filter the entities to archive.
        /// </summary>
        /// <returns><see cref="Expression"/>.</returns>
        protected virtual Expression<Func<TEntity, bool>> ArchiveRuleFilter();

        /// <summary>
        /// Archive an entity.
        /// </summary>
        /// <param name="item">The entity to archive.</param>
        /// <returns><see cref="Task"/>.</returns>
        protected virtual async Task ArchiveItemAsync(TEntity item);

        /// <summary>
        /// Save an entity to the target as flat text JSON into a ZIP archive.
        /// </summary>
        /// <param name="item">The entity to save.</param>
        /// <param name="targetDirectoryPath">Target directory path.</param>
        /// <returns><see cref="Task{bool}"/> that indicates success.</returns>
        protected async Task<bool> SaveItemAsFlatTextCompressedAsync(TEntity item, string targetDirectoryPath);
    }
}
```
Workflow of archive service is following : 
1. `RunAsync()`
   1. `ArchiveItemAsync()` for each items to archive
   2. `SaveItemAsFlatTextCompressedAsync()` for each items to archive

The default archive filter rule is the following : 
   - Entity is fixed
   - Entity has not been already archived **OR** entity has already been archived and last fixed date is superior than archived date

#### Implementation
1. Create your implementation of `IArchiveService` for your entity in **MyCompany.MyProject.Application.MyEntity** namespace :
``` csharp title="MyEntityArchiveService.cs"
namespace MyCompany.MyProject.Application.MyEntity
{
    public class MyEntityArchiveService : ArchiveServiceBase<MyEntity, int>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="MyEntityArchiveService"/> class.
        /// </summary>
        /// <param name="configuration">The configuration.</param>
        /// <param name="archiveRepository">The <see cref="ITGenericArchiveRepository{TEntity, TKey}"/> archive repository.</param>
        /// <param name="logger">The logger.</param>
        public MyEntityArchiveService(IConfiguration configuration, ITGenericArchiveRepository<MyEntity, int> archiveRepository, ILogger<MyEntityArchiveService> logger)

            : base(configuration, archiveRepository, logger)
        {
        }

        /// <inheritdoc/>
        protected override string GetArchiveNameTemplate(MyEntity entity)
        {
            return $"myEntity_{entity.SomeProperty}";
        }
    }
}
```
In case of custom archive repository usage, inject the repository with your custom archive repository interface in the constructor : 
``` csharp title="MyEntityArchiveService.cs"
public class MyEntityArchiveService : ArchiveServiceBase<MyEntity, int>
{
    public MyEntityArchiveService(IConfiguration configuration, IMyEntityArchiveRepository archiveRepository, ILogger<MyEntityArchiveService> logger)
        : base(configuration, archiveRepository, logger)
    {
    }
}
```
If you want to write your own archive filter rule, simply override the method `ArchiveRuleFilter()` :
``` csharp title="MyEntityArchiveService.cs"
public class MyEntityArchiveService : ArchiveServiceBase<MyEntity, int>
{
    /// <inheritdoc/>
    protected override Expression<Func<MyEntity, bool>> ArchiveRuleFilter()
    {
        return x => ... // implement your filter rule
    }
}
```

Instead, if you want to combine base filter rule with your custom implementation, use the `CombineSelector(Expression<Func<T, bool>> secondSelector)` extension : 
``` csharp title="MyEntityArchiveService.cs"
public class MyEntityArchiveService : ArchiveServiceBase<MyEntity, int>
{
    /// <inheritdoc/>
    protected override Expression<Func<MyEntity, bool>> ArchiveRuleFilter()
    {
        return base.ArchiveRuleFilter()
            .CombineSelector(x => ...); // Combine with your custom selector
    }
}
```

2. Configure the dependency injection into the **MyCompany.MyProject.WorkerService** project, in **Startup.cs** file, in `ConfigureServices` method :
``` csharp title="Startup.cs"
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // [...]

        services.AddTransient<IArchiveService, MyEntityArchiveService>();

        // [...]
    }
}
```  

## Run manually
In the **MyCompany.MyProject.WorkerService** project :
1. Open **Worker.cs** file
2. Add execution of the ArchiveTask into `ExecuteAsync()` method :
``` csharp title="Worker.cs"
namespace MyCompany.MyProject.WorkerService
{
    public class Worker : BackgroundService
    {
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            Console.WriteLine(DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss") + ": MyProject Server started.");
            while (!stoppingToken.IsCancellationRequested)
            {
                var client = new BackgroundJobClient();

                // Add new client for the archive task
                client.Create<ArchiveTask>(x => x.Run(), new EnqueuedState());

                this.logger.LogInformation("Worker is alive");
                await Task.Delay(600000);
            }
        }
    }
}
```
3. Run in debug the project **MyCompany.MyProject.WorkerService**