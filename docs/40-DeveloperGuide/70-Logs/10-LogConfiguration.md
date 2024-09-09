---
sidebar_position: 1
---

# Log Configuration
This document explains how to change the configuration of the logs for your project 

## Config File
.Net Bia Framework uses NLog for the management of the logs.
By default, when you create your projects, logs are configured to be written in specific folders. You can find theses configurations in the different appsettings.*.json of your .net Presentation.Api project.
If not set in appsettings.YOUR_ENV.json, the configuration is taken from appsettings.json.
You can change the management of the logs either for all environments by editing appsettings.json or for specific environments with the appsettings.YOUR_ENV.json.

Example : If you decide to send error logs by mail, you can define a different mail address for each environments.

## Personalize log configuration
Notable properties:
**minlevel**: set the level of logs kept. Order: Trace > Debug > Info > Warn > Error > Fatal > Off (Trace logging everything and Off logging Nothing )
**fileName**: change the location and/or name of the log files
**archiveAboveSize**: size limit of a log file. When size is reached, the file is archived and another one is created for subsequent logs
**archiveEvery**: lifetime of a log file. After that time as passed, the file is archived and another one is created for subsequent logs,
**maxArchiveFiles**: number of files kept at a time. After that number is reached, older files are deleted when newer files are created
**layout**: *should not be changed*. Define the structure of the header of each new lines in the log file. The format should be the same for each application for easy interpretation of the logs

For other configuration options, you can look at NLog documentation here : https://nlog-project.org/documentation/