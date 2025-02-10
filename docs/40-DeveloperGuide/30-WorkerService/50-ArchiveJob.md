---
sidebar_position: 1
---

# Archive Job (Worker Feature)
The archive job is a recurred task created to archive entities from database into flat text on a target directory and then delete them from database.

## How it works 
1. Archive job is launched from Hangfire Server throught the Worker Service each day at 04:00 AM (GMT+1).
2. Each injected implementation of `IArchiveService` related to a specific archivable entity (`IEntityArchivable`) of the dabatase will be runned one per one
3. The items to archive will be selected according to following rules from the related `ITGenericArchiveRepository` of the archive service :
   - Entity is fixed
   - Entity has not been already archived **OR** entity has already been archived and last fixed date has been updated since the last 24 hours
4. The selected items are saved into compressed archive file to the target directory one per one : unique file per item, overwritten. Each copy to the target directory is verified by an integrity comparison of checksum.
5. If enable, the items to delete from database will be only those archived more than last past year

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
            "TargetDirectoryPath": "C:\\temp\\archives\\myproject\\myentities",
            "EnableDeleteStep": true,
            "ArchiveMaxDaysBeforeDelete": 365
          }
        ]
      }
    }
  }
}
```
You must set an `ArchiveEntityConfigurations` for each entity to archive.

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
You don't have to implement anything if you comply with the archive and delete rules from the [How it works](#how-it-works) section.  
The BIA Frawmeork will automatically associate the corresponding implementation `TGenericArchiveRepository<TEntity, TKey>` of all interfaces `ITGenericArchiveRepository<TEntity, TKey>` when requested by injection in the archive service (see [next chapter](#archive-service)).

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
        /// Return the items to archive.
        /// </summary>
        /// <returns><see cref="Task{IReadOnlyList{TEntity}}"/>.</returns>
        Task<IReadOnlyList<TEntity>> GetItemsToArchiveAsync();

        /// <summary>
        /// Return the items to delete.
        /// </summary>
        /// <param name="archiveDateMaxDays">The maximum days of archive date of item to delete.</param>
        /// <returns><see cref="IReadOnlyList{TEntity}"/>.</returns>
        Task<IReadOnlyList<TEntity>> GetItemsToDeleteAsync(double? archiveDateMaxDays = 365);

        /// <summary>
        /// Update archive state of an entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <returns><see cref="Task"/>.</returns>
        Task SetAsArchivedAsync(TEntity entity);

        /// <summary>
        /// Remove an entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <returns><see cref="Task"/>.</returns>
        Task RemoveAsync(TEntity entity);
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
        /// Datacontext.
        /// </summary>
        protected readonly IQueryableUnitOfWork dataContext;

        /// <summary>
        /// Initializes a new instance of the <see cref="TGenericArchiveRepository{TEntity, TKey}"/> class.
        /// </summary>
        /// <param name="dataContext">The <see cref="IQueryableUnitOfWork"/> context.</param>
        public TGenericArchiveRepository(IQueryableUnitOfWork dataContext);

        /// <inheritdoc/>
        public virtual async Task<IReadOnlyList<TEntity>> GetItemsToArchiveAsync();

        /// <inheritdoc/>
        public virtual async Task<IReadOnlyList<TEntity>> GetItemsToDeleteAsync(double? archiveDateMaxDays = 365);

        /// <inheritdoc/>
        public async Task SetAsArchivedAsync(TEntity entity);

        /// <inheritdoc/>
        public async Task RemoveAsync(TEntity entity);

        /// <summary>
        /// Selector of items to archive.
        /// </summary>
        /// <returns>Selector expression.</returns>
        protected virtual Expression<Func<TEntity, bool>> ArchiveStepItemsSelector();

        /// <summary>
        /// Selector of items to delete.
        /// </summary>
        /// <param name="archiveDateMaxDays">The maximum days of archive date of item to select.</param>
        /// <returns>Selector expression.</returns>
        protected virtual Expression<Func<TEntity, bool>> DeleteStepItemsSelector(double? archiveDateMaxDays = 365);

        /// <summary>
        /// Return all the entities with automatic includes.
        /// </summary>
        /// <returns><see cref="IQueryable{TEntity}"/>.</returns>
        protected virtual IQueryable<TEntity> GetAllQuery();
    }
}
```
**NOTES :** 
- the method `GetItemsToArchiveAsync()` use the combination of `GetAllQuery()` with where clause using `ArchiveStepItemsSelector()` expression
- the method `GetItemsToDeleteAsync()` use the combination of `GetAllQuery()` with where clause using `DeleteStepItemsSelector()` expression
- the method `GetAllQuery()` returns all the entities with automatic includes :
  - includes all navigation properties at root level of the entity
  - includes recursively all the navigation properties with cascade delete relationship to the entity
  - use `AsSplitQuery()` ([documentation](https://learn.microsoft.com/en-us/ef/core/querying/single-split-queries))
- the method `SetAsArchivedAsync()` will set the `IsArchived` property of the entity to `true` and set the `ArchivedDate` to current date time UTC and commit immediatly
- the method `RemoveAsync()` will delete the entity in database and commit immediatly
  
#### Custom
If you need to customize the default repository : 
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

You can now override existing methods and/or add custom methods to your custom repository.

**NOTE :** if you want to combine base items selector with your custom implementation, use the `CombineSelector(Expression<Func<T, bool>> secondSelector)` extension : 
``` csharp title="MyEntityArchiveRepository.cs"
namespace MyCompany.MyProject.Infrastructure.Data.Repositories.ArchiveRepositories
{
    public class MyEntityArchiveRepository : TGenericArchiveRepository<MyEntity, int>, IMyEntityArchiveRepository
    {
        /// <inheritdoc/>
        protected override Expression<Func<MyEntity, bool>> ArchiveStepItemsSelector()
        {
            return base.ArchiveStepItemsSelector()
              .Include(x => ...) // Add your custom includes
              .CombineSelector(x => ...); // Combine with your custom selector
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
        /// The entity archive configuration.
        /// </summary>
        protected readonly ArchiveEntityConfiguration archiveEntityConfiguration;

        /// <summary>
        /// The entity archive repository.
        /// </summary>
        protected readonly ITGenericArchiveRepository<TEntity, TKey> archiveRepository;

        /// <summary>
        /// The logger.
        /// </summary>
        protected readonly ILogger logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="ArchiveServiceBase{TEntity, TKey}"/> class.
        /// </summary>
        /// <param name="configuration">The configuration.</param>
        /// <param name="archiveRepository">The <see cref="ITGenericArchiveRepository{TEntity, TKey}"/> archive repository.</param>
        /// <param name="logger">The logger.</param>
        protected ArchiveServiceBase(IConfiguration configuration, ITGenericArchiveRepository<TEntity, TKey> archiveRepository, ILogger logger);

        /// <inheritdoc/>
        public async Task RunAsync();

        /// <summary>
        /// Retrive the archive file name template for an entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <returns><see cref="string"/>.</returns>
        protected abstract string GetArchiveNameTemplate(TEntity entity);

        /// <summary>
        /// Run archive step.
        /// </summary>
        /// <returns><see cref="Task"/>.</returns>
        protected virtual async Task RunArchiveStepAsync();

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

        /// <summary>
        /// Run delete step.
        /// </summary>
        /// <returns><see cref="Task"/>.</returns>
        protected virtual async Task RunDeleteStepAsync();

        /// <summary>
        /// Delete an entity.
        /// </summary>
        /// <param name="item">The entity to delete.</param>
        /// <returns><see cref="Task"/>.</returns>
        protected virtual async Task DeleteItemAsync(TEntity item);
    }
}
```
Workflow of archive service is following : 
1. `RunAsync()`
   1. `RunArchiveStepAsync()`
      1. `ArchiveItemAsync()` for each items to archive
      2. `SaveItemAsFlatTextCompressedAsync()` for each items to archive
   2. `RunDeleteStepAsync()` if enabled
      1. `DeleteItemAsync()` for each items to delete

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