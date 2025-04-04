---
sidebar_position: 1
---

# Client for hub (Worker Feature)
This file explains what to use the the hub for client feature in your V3 project.

## Prerequisite

### Knowledge to have:
* [SignalR introduction](https://docs.microsoft.com/fr-fr/aspnet/signalr/overview/getting-started/introduction-to-signalr)

## Overview
The activation of this feature in the worker give the possibility to send message to all connected Clients directly from the worker service.
Concretely the service is connected to a front that propagate the message. 

## Activation
* bianetconfig.json

In the BIANet Section add:
``` json
    "WorkerFeatures": {
      "HubForClients": {
        "Activate": true,
      }
    },
```
* bianetconfig.Development.json
``` json
    "WorkerFeatures": {
      "HubForClients": {
        "SignalRUrl": "http://localhost/[YourProjectName]/WebApi/HubForClients"
      }
    },
```
* bianetconfig.ENV.json (4 files not Development)
In the BIANet Section add:
``` json
    "WorkerFeatures": {
      "HubForClients": {
        "SignalRUrl": "https://[FqdnYourAppServer]/[YourProjectName]/WebApi/HubForClients"
      }
    },
```
replace [FqdnYourAppServer] by the FQDN of your application server
replace [YourProjectName] by the name of your project

## Usage
``` csharp
    using BIA.Net.Core.WorkerService.Features.HubForClients;
    ...
    HubForClientsService.SendMessage("refresh-planes", "");
```