---
sidebar_position: 1
---

# Clean Job
The clean job is a recurred task created to clean entities from database.

## How it works 
1. Clean job is launched from Hangfire Server throught the Worker Service according to the CRON settings.
2. Each injected implementation of `ICleanService` related to a specific entity throught an `ITGenericCleanRepository` will be runned one per one
3. The items to clean will be selected according to clean rule declared the related clean service
4. The items are cleaned from the database

## Configuration
### CRON settings
1. In the **DeployDB** project, the CRON settings of the clean job are set into the `appsettings.json` :
``` json title="appsettings.json"
{
  "Tasks": {
    "Clean": {
      "CRON": "0 4 * * *"
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
                        RecurringJob.AddOrUpdate<CleanTask>($"{projectName}.{typeof(CleanTask).Name}", t => t.Run(), configuration["Tasks:Clean:CRON"]);
                    });
                })
                // [...]
        }
    }
}
```
3. Run the **DeployDB** to update your Hangfire settings with this configuration and enable clean job.


## Implementation
### Clean repository
#### Default
The BIA Frawmeork will automatically associate the corresponding implementation `TGenericCleanRepository<TEntity, TKey>` of all interfaces `ITGenericCleanRepository<TEntity, TKey>` when requested by injection in the clean service (see [next chapter](#clean-service)).

So, you don't have to implement your own clean repository for your entity !  

Here are the description of the interface and the implementation of the default clean repository : 
``` csharp title="ITGenericCleanRepository.cs"
namespace BIA.Net.Core.Domain.RepoContract
{
    /// <summary>
    /// Interface for generic clean repositories of an entity.
    /// </summary>
    /// <typeparam name="TEntity">Entity type.</typeparam>
    /// <typeparam name="TKey">Entity key type.</typeparam>
    public interface ITGenericCleanRepository<TEntity, TKey>
        where TEntity : class, IEntity<TKey>
    {
        /// <summary>
        /// Remove all entities according to the rule.
        /// </summary>
        /// <param name="rule">Filter rule.</param>
        /// <returns><see cref="int"/> that contains the count of cleaned entities.</returns>
        Task<int> RemoveAll(Expression<Func<TEntity, bool>> rule);
    }
}
```

``` csharp title="TGenericCleanRepository.cs"
namespace BIA.Net.Core.Infrastructure.Data.Repositories
{
    /// <summary>
    /// Generic implementation of clean repository for an entity.
    /// </summary>
    /// <typeparam name="TEntity">Entity type.</typeparam>
    /// <typeparam name="TKey">Entity key type.</typeparam>
    public class TGenericCleanRepository<TEntity, TKey> : ITGenericCleanRepository<TEntity, TKey>
        where TEntity : class, IEntity<TKey>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="TGenericCleanRepository{TEntity, TKey}"/> class.
        /// </summary>
        /// <param name="context">The context.</param>
        public TGenericCleanRepository(IQueryableUnitOfWork context);

        /// <summary>
        /// The context.
        /// </summary>
        protected IQueryableUnitOfWork Context { get; }

        /// <inheritdoc/>
        public virtual async Task<int> RemoveAll(Expression<Func<TEntity, bool>> rule);

        /// <summary>
        /// Set the includes to the query.
        /// </summary>
        /// <param name="query">Initial query.</param>
        /// <returns><see cref="IQueryable{TEntity}"/>.</returns>
        protected virtual IQueryable<TEntity> SetIncludes(IQueryable<TEntity> query);
    }
}
```

**NOTES :** in case where the rule to filter on `RemoveAll()` method refers to linked entities, implements your custom clean repository that inherits from `TGenericCleanRepository` and override the `SetIncludes()` method to include the linked entities according to the clean rule :

``` csharp title="MyEntityCleanRepository.cs"
namespace BIA.Net.Core.Infrastructure.Data.Repositories
{
    public class MyEntityCleanRepository : TGenericCleanRepository<MyEntity, int>
    {
        protected override IQueryable<MyEntity> SetIncludes(IQueryable<MyEntity> query)
        {
            return query.Includes(x => ...) // add your includes
        }
    }
}
```

### Clean service
#### Principles
The clean service associated to an entity to clean must inherits from `CleanServiceBase` :
``` csharp title="CleanServiceBase.cs"
namespace BIA.Net.Core.Application.Clean
{
    /// <summary>
    /// Abstract class for all clean services of an entity.
    /// </summary>
    /// <typeparam name="TEntity">Entity type.</typeparam>
    /// <typeparam name="TKey">Entity key type.</typeparam>
    public abstract class CleanServiceBase<TEntity, TKey> : ICleanService
        where TEntity : class, IEntity<TKey>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="CleanServiceBase{TEntity, TKey}"/> class.
        /// </summary>
        /// <param name="cleanRepository">The clean repository.</param>
        /// <param name="logger">The logger.</param>
        protected CleanServiceBase(ITGenericCleanRepository<TEntity, TKey> cleanRepository, ILogger logger);

        /// <summary>
        /// The clean repository.
        /// </summary>
        protected ITGenericCleanRepository<TEntity, TKey> CleanRepository { get; }

        /// <summary>
        /// Logger.
        /// </summary>
        protected ILogger Logger { get; }

        /// <inheritdoc/>
        public virtual async Task RunAsync();

        /// <summary>
        /// The rule to filter the entities to clean.
        /// </summary>
        /// <returns><see cref="Expression"/>.</returns>
        protected abstract Expression<Func<TEntity, bool>> CleanRuleFilter();
    }
}
```
When the service is started with `RunAsync()` method, the `RemoveAll()` method of `ITGenericCleanRepository` will be called with the `CleanRuleFilter()` expression.

#### Implementation
1. Create your implementation of `ICleanService` for your entity in **MyCompany.MyProject.Application.MyEntity** namespace :
``` csharp title="MyEntityCleanService.cs"
namespace MyCompany.MyProject.Application.MyEntity
{
    public class MyEntityCleanService : CleanServiceBase<MyEntity, int>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="MyEntityCleanService"/> class.
        /// </summary>
        /// <param name="cleanRepository">The clean repository for the entity.</param>
        /// <param name="logger">The logger.</param>
        public MyEntityCleanService(ITGenericCleanRepository<MyEntity, int> cleanRepository, ILogger<MyEntityCleanService> logger)
            : base(cleanRepository, logger)
        {
        }

        /// <inheritdoc/>
        protected override Expression<Func<MyEntity, bool>> CleanRuleFilter()
        {
            // Implements here your clean rule for the entity
            return x => x.Property == value;
        }
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

        services.AddTransient<ICleanService, MyEntityCleanService>();

        // [...]
    }
}
```  

## Run manually
In the **MyCompany.MyProject.WorkerService** project :
1. Open **Worker.cs** file
2. Add execution of the CleanTask into `ExecuteAsync()` method :
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

                // Add new client for the clean task
                client.Create<CleanTask>(x => x.Run(), new EnqueuedState());

                this.logger.LogInformation("Worker is alive");
                await Task.Delay(600000);
            }
        }
    }
}
```
3. Run in debug the project **MyCompany.MyProject.WorkerService**