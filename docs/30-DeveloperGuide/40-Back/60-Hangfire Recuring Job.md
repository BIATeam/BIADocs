---
layout: default
title: Hangfire Recurring Job
parent: Back
grand_parent: Developer guide
nav_order: 50
---

# Hangfire Reccuring Job
This document explains how to implement a recuring job with hangfire


## Create the application Job
Proceed like a DelegatedJob : [Delegate job to worker](../20-Features/30-DelegateJobToWorker.md)
Do not do the "Call the job" step.


## Add your Task CRON 
### Calculate the CRON 
You can use the site [https://crontab.cronhub.io/](https://crontab.cronhub.io/) to calculate the cron.

### Complete the Tasks parameters
Edit your DeployDB/appsetting.json
ex:
```json
  "Tasks": {
    "WakeUp": {
      "CRON": "0 6-17 * * *"
    },
    "SynchronizeUser": {
      "CRON": "0 6 * * *"
    }
  },
```

### Record the cron at db deployement :
Edit  your DeployDB/Program.cs
```csharp
    services.AddHangfire(config =>
    {
        config.UseSqlServerStorage(configuration.GetConnectionString("BIADemoDatabase"));
        string projectName = configuration["Project:Name"];

        // Initialize here the recuring jobs
        RecurringJob.AddOrUpdate<WakeUpTask>($"{projectName}.{typeof(WakeUpTask).Name}", t => t.Run(), configuration["Tasks:WakeUp:CRON"]);
        RecurringJob.AddOrUpdate<SynchronizeUserTask>($"{projectName}.{typeof(SynchronizeUserTask).Name}", t => t.Run(), configuration["Tasks:SynchronizeUser:CRON"]);
    });
```
