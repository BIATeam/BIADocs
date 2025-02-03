---
sidebar_position: 1
---

# Archive Job (Worker Feature)
The archive job is a recurred task created to archive entities from database into flat text on a target directory and then delete them from database.

## How it works
Following descriptions will use defaults values of the archive job set in the BIA Framework.  

1. Archive job is launched from Hangfire throught the Worker Service each day at 04:00 AM (GMT+1).
2. Each injected implementation of `IArchiveService` related to a specific archivable entity (`IEntityArchivable` that inherits from `IEntityFixable`) of the dabatase will be runned one per one
3. The items to archive will be selected according to following rules from the related `ITGenericArchiveRepository` of the archive service :
   - Entity is fixed
   - Entity has not been already archived **OR** entity has already been archived and last fixed date has been updated since the last 24 hours
4. The selected items are saved into compressed archive file to the target directory one per one (one file per item, overwritten)
5. If enable, the items to delete from database will be only those archived more than last past year

## Configuration
### CRON settings
In the **DeployDB** project, the CRON settings of the archive job are set into the `appsettings.json` :
``` json title="appsettings.json"
{
  "Tasks": {
    "Archive": {
      "CRON": "0 3 * * *"
    }
  }
}
```
Run the **DeployDB** to update your Hangfire settings with this configuration and enable archive job.

### Archive job
In the **WorkerService** project, the settings for the archive job are set into the `bianetconfig.json` :
``` json title="appsettings.json"
{
  "BiaNet": {
    "WorkerFeatures": {
      "Archive": {
        "IsActive": true,
        "ArchiveEntityConfigurations": [
          {
            "EntityName": "Plane",
            "TargetDirectoryPath": "C:\\temp\\archives\\biademo\\planes",
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
### Archive repository
#### Default
#### Custom
### Archive service

## Run manually