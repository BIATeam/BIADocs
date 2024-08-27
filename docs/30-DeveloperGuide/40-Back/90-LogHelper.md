---
layout: default
title: Log Helper
parent: Back
grand_parent: Developer guide
nav_order: 90
---

# Log Helper
This document explains how to use the log helper to log the execution time of functions or intructions

## Usage
A log utility class LogHelper is available in the framework in Crosscutting.Common.Helpers to help log execution times of functions.
Two methods are available :
1) "Begin" that returns a Stopwatch (from System.Diagnostics) that starts at the call of the function
2) "End" that takes the Stopwatch as a parameter to log the elapsed time between the Begin and End functions.

## Example

LogHelper functions take the logger of your application as first parameter. You can get it by injecting ILogger in your contructor or if you have access to serviceProvider by calling serviceProvider.GetService<ILogger<MyService>>();

```csharp
using Safran.MyProject.Crosscutting.Common.Helpers;

public class MyService
{
    // My logger
    private readonly ILogger<MyService> logger;

    // Constructor
    public MyService(ILogger<MyService> logger) 
    {
        this.logger = logger;
    }

    // Function to log
    public void MyFunction()
    {
        string methodName = nameof(this.MyFunction);
        string className = this.GetType().Name;
        Stopwatch stopwatch = LogHelper.Begin(this.logger, className, methodName);

        // My instructions
        ...
        ...
        ...
        // End of my instructions

        LogHelper.End(this.logger, className, methodName, stopwatch);
    }
}
```