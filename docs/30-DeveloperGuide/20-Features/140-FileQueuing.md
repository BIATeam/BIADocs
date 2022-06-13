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

### how to serialize/deserialize a file

File are transfered by FileQueueDto :
```csharp
    /// <summary>
    /// DTO of File Queue
    /// </summary>
    [Serializable]
    public class FileQueueDto
    {
        /// <summary>
        /// Gets or Sets the filename.
        /// </summary>
        public string FileName { get; set; }

        /// <summary>
        /// Gets or Sets the output path folder to put the file.
        /// </summary>
        public string OutputPath { get; set; }

        /// <summary>
        /// Gets or sets the data of the files en bytes.
        /// </summary>
        public byte[] Data { get; set; }
    }
```

which can be instanciate from a file path :

```csharp
    FileQueueDto file = new FileQueueDto();
    file.FileName = System.IO.Path.GetFileName(filePath);
    file.OutputPath = outputPath;
    file.Data = File.ReadAllBytes(filePath);
```

### How to recieve a file

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

Then subscribe to the observable, create a QueueDto

```csharp
    /// <summary>
    /// Dto to define address of RabbitMQ server and queue.
    /// </summary>
    public class QueueDto
    {
        /// <summary>
        /// The RabbitMQ server URI.
        /// </summary>
        public string Endpoint { get; set; }

        /// <summary>
        /// The rabbitMQ Queue to listen
        /// </summary>
        public string QueueName { get; set; }
    }
```

```csharp
    private readonly IFileQueueRepository fileQueueRepository;
	
	...
	
	fileQueueRepository.Configure(fileRecieverConfigurations.Select(x => new QueueDto { Endpoint = XXX, QueueName = YYY }));
	fileQueueRepository.Subscribe(fileRecieverHandler);
```

### How to send a file

To send, juste use SendFile method with server URI, queue name and a FileQueueDto

```csharp
    private readonly IFileQueueRepository fileQueueRepository;
	
	...
	
	fileQueueRepository.SendFile(Seveur, queueName, file);
```
