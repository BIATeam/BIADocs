---
sidebar_position: 130
---

# Multiple Database

By default only single database can be set in order to be used in all the `ITGenericRepository` implementations for each entity into BIA Framework from the `appsettings.json` of the API or Worker project :
``` json title="appsettings.json"
{
  "ConnectionStrings": {
    "ProjectDatabase": "data source=localhost;initial catalog=MyDatabase;integrated security=True;MultipleActiveResultSets=True;Encrypt=False;App=MyApplication"
  },
}
```

This page will explain how to use multiple database for your repositories inside the BIA Framework 

## Datacontext Factory
The `DataContextFactory` allows you to store different instances of `IQueryableUnitOfWork` as `DataContext` or provide a new instance of `IQueryableUnitOfWorkNoTracking` as `DataContextNoTracking` based on multiple database configurations set in the `appsettings.json` :
``` json title="appsettings.json"
{
  "ConnectionStrings": {
    "ProjectDatabase": "data source=localhost;initial catalog=MyDatabase;integrated security=True;MultipleActiveResultSets=True;Encrypt=False;App=MyApplication"
  },
  "DatabaseConfigurations": [
    {
      "Key": "ProjectSecondDatabase",
      "Provider": "SQLServer",
      "ConnectionString": "data source=localhost;initial catalog=MySecondDatabase;integrated security=True;MultipleActiveResultSets=True;Encrypt=False;App=MyApplication"
    },
    {
      "Key": "ProjectThirdDatabase",
      "Provider": "SQLServer",
      "ConnectionString": "data source=localhost;initial catalog=MyThirdDatabase;integrated security=True;MultipleActiveResultSets=True;Encrypt=False;App=MyApplication"
    }
  ]
}
```
For each new scope, the `DataContextFactory` will create and store the instances of `IQueryableUnitOfWork` as `DataContext` with the provided `key` of your configuration :
``` csharp title="DataContextFactory.cs"
namespace MyCompany.MyProject.Infrastructure.Data
{
    public class DataContextFactory
    {
        private readonly IServiceProvider serviceProvider;
        private readonly IConfiguration configuration;
        private readonly Dictionary<string, IQueryableUnitOfWork> queryableUnitOfWorks = new ();
        private readonly List<DatabaseConfiguration> databaseConfigurations;

        public DataContextFactory(IServiceProvider serviceProvider, IConfiguration configuration)
        {
            this.serviceProvider = serviceProvider;
            this.configuration = configuration;
            this.databaseConfigurations = configuration.GetSection("DatabaseConfigurations").Get<List<DatabaseConfiguration>>();
            this.FillQueryableUnitOfWorks();
        }

        private void FillQueryableUnitOfWorks()
        {
            foreach (var databaseConfiguration in this.databaseConfigurations)
            {
                var queryableUnitOfWork = this.CreateDataContext(databaseConfiguration);
                this.queryableUnitOfWorks.TryAdd(databaseConfiguration.Key, queryableUnitOfWork);
            }
        }

        private DataContext CreateDataContext(DatabaseConfiguration databaseConfiguration)
        {
            var dataContextLogger = this.serviceProvider.GetRequiredService<ILoggerFactory>().CreateLogger<DataContext>();
            var dataContextOptions = new DbContextOptionsBuilder<DataContext>();
            ConfigureDataContextOptionsProvider(databaseConfiguration, dataContextOptions);
            dataContextOptions.EnableSensitiveDataLogging();
            dataContextOptions.AddInterceptors(new AuditSaveChangesInterceptor());
            return new DataContext(dataContextOptions.Options, dataContextLogger, this.configuration);
        }

        private static void ConfigureDataContextOptionsProvider(DatabaseConfiguration databaseConfiguration, DbContextOptionsBuilder<DataContext> dataContextOptions)
        {
            switch (databaseConfiguration.Provider.ToLower())
            {
                case "sqlserver":
                    dataContextOptions.UseSqlServer(databaseConfiguration.ConnectionString);
                    break;
                case "postgresql":
                    dataContextOptions.UseNpgsql(databaseConfiguration.ConnectionString);
                    break;
                default:
                    throw new NotImplementedException($"Provider {databaseConfiguration.Provider} not handled.");
            }
        }
    }
}
```

The instances will be available by requesting the `GetQueryableUnitOfWork` method with the required `key` of the database : 
``` csharp title="DataContextFactory.cs"
public IQueryableUnitOfWork GetQueryableUnitOfWork(string key)
{
    if (this.queryableUnitOfWorks.TryGetValue(key, out IQueryableUnitOfWork unitOfWork))
    {
        return unitOfWork;
    }

    throw new InvalidOperationException($"Unable to find {nameof(IQueryableUnitOfWork)} with key {key}");
}
```

You can request a new implementation of `IQueryableUnitOfWorkNoTracking` with the following method : 
``` csharp title="DataContextFactory.cs"
public IQueryableUnitOfWorkNoTracking GetQueryableUnitOfWorkNoTracking(string key)
{
    var databaseConfiguration = this.databaseConfigurations.Find(x => x.Key == key)
        ?? throw new InvalidOperationException($"Unable to find {nameof(DatabaseConfiguration)} with key {key}");

    return this.CreateDataContextNoTracking(databaseConfiguration);
}

private DataContextNoTracking CreateDataContextNoTracking(DatabaseConfiguration databaseConfiguration)
{
    var dataContextLogger = this.serviceProvider.GetRequiredService<ILoggerFactory>().CreateLogger<DataContextNoTracking>();
    var dataContextOptions = new DbContextOptionsBuilder<DataContext>();
    ConfigureDataContextOptionsProvider(databaseConfiguration, dataContextOptions);
    dataContextOptions.EnableSensitiveDataLogging();
    return new DataContextNoTracking(dataContextOptions.Options, dataContextLogger, this.configuration);
}
```

The `DataContextFactory` is injected as scoped into the IOC container.

**NOTE :** You can create your own factory with your own contexts and configurations. The `DataContextFactory` is only applicable for the `DataContext` instances.

## Database Repository
Once the `DataContextFactory` created, you will now use it to build the repository of an entity that will need one of your multiple database. 

Instead inherit directly from `TGenericRepositoryEF<TEntity, TKey>`, your custom repository must inherit from **`DatabaseRepositoryBase<TEntity, TKey>`** (that inherits herself from `TGenericRepositoryEF<TEntity, TKey>`).  
Create all your database repositories into the **Infrastructure.Data** project inside the **Repositories** folder. 

You'll must fill the key of your database in the base constructor to use with the `DataContextFactory` to retrieve the instance of the `IQueryableUnitOfWork` to use with your repository :
``` csharp title="MySecondDatabaseRepository"
namespace MyCompany.MyProject.Infrastructure.Data.Repositories
{
    public class MySecondDatabaseRepository<TEntity, TKey> : DatabaseRepositoryBase<TEntity, TKey>, IMySecondDatabaseRepository<TEntity, TKey>
        where TEntity : class, IEntity<TKey>
    {
        public MySecondDatabaseRepository(DataContextFactory dataContextFactory, IServiceProvider serviceProvider)
            : base(dataContextFactory, serviceProvider, "ProjectSecondDatabase")
        {
        }
    }
}
```

Don't forget to declare the corresponding interface into the **Domain** project inside **RepoContract** folder :
``` csharp title="IMySecondDatabaseRepository"
namespace MyCompany.MyProject.Domain.RepoContract
{
    public interface IMySecondDatabaseRepository<TEntity, TKey> : ITGenericRepository<TEntity, TKey>
        where TEntity : class, IEntity<TKey>
    {
    }
}
```

You can know use your repository like other one by injecting it into your application services :
``` csharp title="MyEntityService"
namespace MyCompany.MyProject.Application.MyEntity
{
    public class MyEntityAppService : CrudAppServiceBase<MyEntityDto, MyEntity, int, PagingFilterFormatDto, MyEntityMapper>, IMyEntityAppService
    {
        public MyEntityAppService(IMySecondDatabaseRepository<MyEntity, int> repository)
            : base(repository)
        {
        }
    }
}
```
