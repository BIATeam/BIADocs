---
layout: default
title: File Queuing
parent: Features
grand_parent: Developer guide
nav_order: 140
---

# File Queuing

This file explains how to send and recieve File by Queuing (RabbitMQ).

## Overview

The BIA.Net.Queue autorise to send/Receive file by Message Queuing using a RabbitMQ server.

## How to install

First install a rabbitMQ server.
https://www.rabbitmq.com/install-windows.html

Add BIA.Net.Queue's Packages from nuget.org on the the proper project in your solution.
BIA.Net.Queue.Domain
BIA.Net.Queue.Domain.Dto
BIA.Net.Queue.Infrastructure.Service
BIA.Net.Queue.Crosscutring.Common

Add the following line in the infrastructureservice methods in IOCContainer Class.

```csharp
private static void ConfigureInfrastructureServiceContainer(IServiceCollection collection)
{
     // Infrastructure Service Layer
     collection.AddTransient<IFileQueueRepository, FileQueueRepository>();
}
```

### How to use it

To recieve a file, create an observer of FileQueueDto

```csharp
	public class FileReceiverHandler : IObserver<FileQueueDto>
    {
        public void OnCompleted()
        {
            throw new NotImplementedException();
        }

        public void OnError(Exception error)
        {
            throw new NotImplementedException();
        }

        public void OnNext(FileQueueDto value)
        {
            if (value != null && !string.IsNullOrEmpty(value.FileName) && !string.IsNullOrEmpty(value.OutputPath) && value.Data.Length > 0)
            {
                // TODO
            }
        }
    }
	
```


```csharp
    private readonly IFileQueueRepository fileQueueRepository;
	
	...
	
	fileQueueRepository.Configure(fileRecieverConfigurations.Select(x => new QueueDto { Endpoint = XXX, QueueName = YYY }));
	fileQueueRepository.Subscribe(fileRecieverHandler);
	
```

### Back End

On your web server, disable windows authentication for your back end application.

At the source code level, in the **launchSettings.json** file, Change these settings as follows:

```json
{
  "iisSettings": {
    "windowsAuthentication": false,
    "anonymousAuthentication": true,
    ...
  },
}
```

In **Api.Controllers.Base.AuthControllerBase**, replace **BiaControllerBaseNoToken** by **BiaControllerBaseIdP**

```
public abstract class AuthControllerBase : BiaControllerBaseIdP
```

Add the Keycloak configuration in your different files **bianetconfig.XXX.json**

(Values are to be adapted according to your Keycloak)

```json
"Authentication": {
      "Keycloak": {
        "BaseUrl": "http://localhost:8080",
        "Configuration": {
          "Authority": "/realms/BIA-Realm",
          "RequireHttpsMetadata": false,
          "ValidAudience": "account"
        },
        "Api": {
          "TokenConf": {
            "RelativeUrl": "/realms/BIA-Realm/protocol/openid-connect/token",
            "ClientId": "biademo-front",
            "GrantType": "password",
            "CredentialKeyInWindowsVault": "BIA:KeycloakSearchUserAccount"
          },
          "SearchUserRelativeUrl": "/admin/realms/BIA-Realm/users"
        }
      },
      ...
}
```

The login and password of the keycloak account that owns the role **view-users** must be registered in the vault via this command while connected with the application pool account:

```bat
%windir%\system32\cmdkey.exe /generic:BIA:KeycloakSearchUserAccount /user:"MyLogin" /pass:"MyPassword"
```