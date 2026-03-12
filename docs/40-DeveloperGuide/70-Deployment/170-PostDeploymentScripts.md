---
sidebar_position: 170
---

# Execute post deployment scripts
## Adding scripts
All the scripts must be added as **embedded resources** into the **Infrastructure.Data** project and ending with `.sql` or `.SQL` extension.  

You are free to select your storage folder inside the project, but the BIAFramework has already a dedicated folder `Scripts\PostDeployment` for this usage. Ensure to have the same folder name into the next step.
## Running scripts automatically
1. In the **DeployDB** project, open the `DeployDBService` class
2. Ensure to have a call to the method `RunScriptsFromAssemblyEmbeddedResourcesFolder()` from the datacontext after the `Migrate()` method :
``` csharp title="DeployDBService.cs
internal sealed class DeployDBService : IHostedService
{
    public Task StartAsync(CancellationToken cancellationToken)
    {
        this.appLifetime.ApplicationStarted.Register(() =>
        {
            Task.Run(async () =>
            {
                try
                {
                    // [...]

                    this.dataContext.Database.Migrate();

                    // Add the post deployment script execution here
                    await this.dataContext.RunScriptsFromAssemblyEmbeddedResourcesFolder(
                        typeof(DataContext).Assembly, // Better way to retrieve the assembly where the embedded resources scripts are stored
                        "Scripts.PostDeployment" // Ensure that the folder name matches
                    );

                    // [...]
                }
                catch (Exception ex)
                {
                    // [...]
                }
            });
        });
    }
}
```

The method will execute automatically all the scripts stored into the embedded resources folder of the assembly.
  
