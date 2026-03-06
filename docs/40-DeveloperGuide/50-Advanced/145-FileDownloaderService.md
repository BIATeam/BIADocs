---
sidebar_position: 145
---

# BiaFileDownloaderService

## Overview

The `BiaFileDownloaderService` is a built-in BIA framework service that handles **asynchronous file download workflows**. It covers the full lifecycle of making a generated file securely available to a specific user:

1. **Store** file metadata (path, name, content type, availability) in the database.
2. **Notify** the target user via an in-app notification when the file is ready.
3. **Issue a one-time token** so the file can be downloaded securely without exposing server paths.
4. **Stream the file** through the built-in `FilesController` endpoint.
5. **Clean up** expired or downloaded files automatically.

This service is particularly useful for long-running export tasks where the file cannot be returned synchronously in the HTTP response.

## How It Works

The `IFileDownloaderService` interface exposes five methods that together cover the complete download lifecycle:

| Method | Description |
|---|---|
| `NotifyDownloadReadyAsync` | Persists file metadata to the database and sends a `DownloadReady` in-app notification to the requesting user. |
| `PrepareBackgroundDownload<TService>` | Enqueues a Hangfire background job that calls a specified method on a DI-registered service, then automatically calls `NotifyDownloadReadyAsync` once the file is ready. |
| `GenerateDownloadToken` | Generates a single-use download token for a given file, after verifying that the requesting user is the file's owner. |
| `GetFileDownloadData` | Validates a download token and returns the file metadata. The token is consumed (deleted) on use. |
| `RemoveFileToDownload` | Deletes the file from disk and removes its database record, optionally deleting the associated in-app notification. |

Regardless of how the file was generated, the front-end download flow is always the same:

1. The front-end receives the in-app `DownloadReady` notification (via SignalR or polling).
2. The user clicks the notification → the front calls `GET /api/files/{guid}/getdownloadtoken` (authenticated) to obtain a single-use token.
3. The front navigates to `GET /api/files/{guid}/download?token=...` → the token is validated, the file is streamed to the browser, and the token is immediately deleted.

:::info
The download token is **single-use** and is consumed immediately after the file is streamed. A fresh token can be requested at any time via `GetDownloadToken`, as long as the file has not expired.
:::

## Configuration

### 1. Register the service in the IoC container

The `IFileDownloaderService` is **excluded from BIA's automatic registration** because `BiaFileDownloaderOptions` and `BiaFileDownloaderService` are both **abstract** — your project must provide concrete subclasses. You must register them manually in your `IocContainer`:

```csharp title="Crosscutting.Ioc/IocContainer.cs"
// Configure the language IDs used for the DownloadReady notification translations
param.Collection.Configure<FileDownloaderOptions>(options =>
{
    options.FrenchLanguageId  = LanguageId.French;
    options.EnglishLanguageId = LanguageId.English;
    options.SpanishLanguageId = LanguageId.Spanish;
});

// Register your project-level service implementation
param.Collection.AddTransient<IFileDownloaderService, FileDownloaderService>();
```

:::tip
Because `BiaFileDownloaderOptions` and `BiaFileDownloaderService` are **abstract**, every project must provide its own concrete subclasses — `FileDownloaderOptions` and `FileDownloaderService`. These classes are **already included in the BIA project template**, so no manual creation is needed in a standard project setup. See [Extending the Service](#extending-the-service) for the complete details.
:::

### 2. Verify Hangfire is registered

Background downloads rely on `IBackgroundJobClient` from Hangfire. Make sure it is registered:

```csharp
collection.AddTransient<IBackgroundJobClient, BackgroundJobClient>();
```

:::note
The BIA framework IoC already includes this line by default. You only need to add it if your project overrides the default registration.
:::

### 3. Configure the file server path

Both use cases write generated files to disk. The path is resolved from the `FileServer:MainFolder` configuration key.

:::warning
The `Presentation.Api` (which triggers the download or enqueues the job) and the `WorkerService` (which executes the Hangfire job and writes the file) can run on **different servers**. In that case, `FileServer:MainFolder` must resolve to the **same shared network storage** in the `appsettings.json` of both projects — otherwise the file written by the worker will not be found by the API when streaming it to the browser.
:::

Add the key to the `appsettings.json` of both the `Presentation.Api` and the `WorkerService` projects:

```json title="appsettings.json (Presentation.Api and WorkerService)"
{
  "FileServer": {
    "MainFolder": "\\\\shared-server\\YourApp\\FileServer"
  }
}
```

:::warning
Make sure the configured folder exists and the application process has **write permissions** on both servers. In production environments, use a path outside the application's web root to avoid exposing generated files directly.
:::

---

## Use Case 1 – Direct Notification

Use this approach when your application service can **generate the file within its own operation** before returning. The service writes the file to disk and immediately calls `NotifyDownloadReadyAsync`, which stores the file metadata and sends an in-app `DownloadReady` notification to the user. The user can then download the file at any point during the configured availability window.

This is the simplest approach — no background job is involved. It is suitable for files that can be generated quickly. **The HTTP request blocks until the file is generated and the in-app notification is sent**, so the user waits for the `204 No Content` response for the entire duration of the operation. For long-running generation, prefer [Use Case 2](#use-case-2--background-job-hangfire).

### Step 1 – Generate the file and call `NotifyDownloadReadyAsync`

Inject `IFileDownloaderService` into your application service, generate the file, then call `NotifyDownloadReadyAsync`. The example below is taken directly from BIADemo (`ExampleAppService`):

```csharp title="Application/Example/ExampleAppService.cs"
public class ExampleAppService : IExampleAppService
{
    private readonly IFileDownloaderService fileDownloaderService;
    private readonly string fileServerMainFolderPath;

    public ExampleAppService(IConfiguration configuration, IFileDownloaderService fileDownloaderService)
    {
        this.fileDownloaderService = fileDownloaderService;
        // Read from configuration — must match the same path configured in the WorkerService appsettings.
        // The ?? Path.GetTempPath() fallback is used in BIADemo for demo convenience only;
        // always configure FileServer:MainFolder explicitly in production.
        this.fileServerMainFolderPath = configuration.GetSection("FileServer").GetValue<string>("MainFolder") ?? Path.GetTempPath();
    }

    public async Task NotifyDownloadReadyFileExample(int requestedByUserId)
    {
        // 1. Generate the file on disk (prefix with a GUID to avoid name collisions)
        var tempFilePath = Path.Combine(this.fileServerMainFolderPath, "Example", $"{Guid.NewGuid()}_FileExample.txt");
        Directory.CreateDirectory(Path.GetDirectoryName(tempFilePath));
        const string content = "This is an example file.";
        await File.WriteAllTextAsync(tempFilePath, content);

        // 2. Build the FileDownloadDataDto using the static Create() factory method.
        //    Always use FileDownloadDataDto.Create() — never instantiate the DTO directly.
        //    fileContentType must be a valid HTML MIME type recognized by the browser.
        var fileDownloadData = FileDownloadDataDto.Create(
            "FileExample.txt",
            "text/plain; charset=utf-8",
            tempFilePath,
            TimeSpan.FromMinutes(1)); // optional but strongly recommended

        // 3. Notify the user — persists metadata to DB and sends the in-app notification
        await this.fileDownloaderService.NotifyDownloadReadyAsync(fileDownloadData, requestedByUserId);
    }
}
```

### Step 2 – Call from the controller

```csharp title="Presentation.Api/Controllers/Example/ExamplesController.cs"
[HttpPost("[action]")]
[ProducesResponseType(StatusCodes.Status204NoContent)]
public async Task<IActionResult> GenerateFileDownloadNotification()
{
    await this.exampleAppService.NotifyDownloadReadyFileExample(this.biaClaimsPrincipalService.GetUserId());
    return this.NoContent();
}
```

:::note
The controller method is `async` and awaits the complete operation. Both the file generation and the notification creation must finish before the `204 No Content` is returned to the caller. The HTTP request therefore **blocks for the full duration of the file generation**. This is acceptable for quick operations, but if generation takes more than a few seconds, use [Use Case 2](#use-case-2--background-job-hangfire) instead.
:::

### What happens internally

When `NotifyDownloadReadyAsync` is called, the service:

1. Validates that `FilePath`, `FileName`, and `FileContentType` are provided.
2. Persists a `FileDownloadData` record to the database (via `IFileDownloadDataAppService`).
3. Creates a `DownloadReady` in-app notification targeted to the requesting user, with translations for French, English, and Spanish.

---

## Use Case 2 – Background Job (Hangfire)

Use this approach when file generation is **long-running** (e.g., large data exports, heavy computation, external system calls) and must not block an HTTP request. The controller calls `PrepareBackgroundDownload`, which immediately enqueues a Hangfire job and returns `204 No Content`. The `WorkerService` picks up the job, executes the generation method, and automatically calls `NotifyDownloadReadyAsync` — the user is notified once the file is ready, with no blocking on the HTTP side.

This is the recommended approach for any file that takes more than a few seconds to produce.

### Step 1 – Define the generation method on your service interface

The service interface must expose two methods:
- A **trigger method** (`void`, synchronous) that calls `PrepareBackgroundDownload` — this is what the controller calls and what returns immediately without blocking.
- A **generation method** matching the signature `Task<FileDownloadDataDto> YourMethod(...)` — this is the method the Hangfire job will invoke via reflection in the `WorkerService`.

The example below is taken directly from BIADemo (`IBiaDemoTestHangfireService`):

```csharp title="Application/Job/IBiaDemoTestHangfireService.cs"
public interface IBiaDemoTestHangfireService
{
    /// <summary>
    /// Enqueues the background job. Returns immediately without waiting for the file to be generated.
    /// </summary>
    void PrepareBackgroundDownloadFileExample(int requestedByUserId);

    /// <summary>
    /// Called by the Hangfire job inside the WorkerService. Generates the file and returns its metadata.
    /// </summary>
    Task<FileDownloadDataDto> GenerateExampleFileAsync(string fileName);
}
```

### Step 2 – Implement the service

The example below is taken directly from BIADemo (`BiaDemoTestHangfireService`). Only the members relevant to the file downloader are shown:

```csharp title="Application/Job/BiaDemoTestHangfireService.cs"
public class BiaDemoTestHangfireService : BaseJob, IBiaDemoTestHangfireService
{
    private readonly IFileDownloaderService fileDownloaderService;
    private readonly string fileServerMainFolderPath;

    public BiaDemoTestHangfireService(
        IConfiguration configuration,
        ILogger<BiaDemoTestHangfireService> logger,
        IFileDownloaderService fileDownloaderService)
        : base(configuration, logger)
    {
        this.fileDownloaderService = fileDownloaderService;
        // Read from configuration — must match the same path configured in the Presentation.Api appsettings.
        // The ?? Path.GetTempPath() fallback is used in BIADemo for demo convenience only;
        // always configure FileServer:MainFolder explicitly in production.
        this.fileServerMainFolderPath = configuration.GetSection("FileServer").GetValue<string>("MainFolder") ?? Path.GetTempPath();
    }

    /// <inheritdoc/>
    public void PrepareBackgroundDownloadFileExample(int requestedByUserId)
    {
        // Enqueues the Hangfire job and returns immediately — the HTTP response is not blocked.
        this.fileDownloaderService.PrepareBackgroundDownload<IBiaDemoTestHangfireService>(
            requestedByUserId,
            x => x.GenerateExampleFileAsync("GeneratedFileExample.txt"));
    }

    /// <inheritdoc/>
    public async Task<FileDownloadDataDto> GenerateExampleFileAsync(string fileName)
    {
        // Simulate long-running work (e.g. querying a database, generating a report…)
        await Task.Delay(5000);

        // Always use FileDownloadDataDto.Create() — never instantiate the DTO directly.
        // fileContentType must be a valid HTML MIME type recognized by the browser.
        var tempFilePath = Path.Combine(this.fileServerMainFolderPath, "Hangfire", $"{Guid.NewGuid()}_{fileName}");
        Directory.CreateDirectory(Path.GetDirectoryName(tempFilePath));
        const string content = "This is an example file generated by an Hangfire task.";
        await File.WriteAllTextAsync(tempFilePath, content);

        return FileDownloadDataDto.Create(fileName, "text/plain; charset=utf-8", tempFilePath, TimeSpan.FromMinutes(1));
    }
}
```

:::tip
In this use case, the file is **written by the `WorkerService`** (inside the Hangfire job) but **read and streamed by the `Presentation.Api`**. Ensure that `FileServer:MainFolder` is configured to the same shared network path in the `appsettings.json` of both projects. See [Configuration – step 3](#3-configure-the-file-server-path) for details.
:::

### Step 3 – Call from the controller

Notice that unlike Use Case 1, the controller method is **synchronous** (no `async`/`await`). It simply enqueues the job and returns `204 No Content` at once, without waiting for the file to be generated.

```csharp title="Presentation.Api/Controllers/Example/HangfiresController.cs"
[HttpPost("[action]")]
[ProducesResponseType(StatusCodes.Status204NoContent)]
public IActionResult PrepareBackgroundDownloadFileExample()
{
    this.biaDemoTestHangfireService.PrepareBackgroundDownloadFileExample(
        this.biaClaimsPrincipalService.GetUserId());
    return this.NoContent();
}
```

:::tip
Because `PrepareBackgroundDownloadFileExample` is a fire-and-forget void method, the HTTP response returns **immediately**, regardless of how long the file generation takes. The in-app `DownloadReady` notification will appear once the `WorkerService` completes the job.
:::

### What happens internally

When `PrepareBackgroundDownload` is called, the service:

1. Extracts the target method name and arguments from the expression.
2. Serializes them to JSON so they survive the Hangfire job boundary.
3. Enqueues a `PrepareDownloadTask` Hangfire job.
4. The worker picks up the job, resolves your service from DI, invokes the generation method, then automatically calls `NotifyDownloadReadyAsync`.

:::warning
The generation method is resolved **by reflection** inside the Hangfire worker. Arguments passed in the expression must be **JSON-serializable**. Avoid passing complex objects that cannot survive serialization; prefer scalar values (IDs, strings, enums).
:::

:::warning
Because the job is retried by Hangfire's default policy, the `PrepareDownloadTask` is decorated with `[AutomaticRetry(Attempts = 0)]` to avoid generating duplicate files and notifications if the job fails. Make sure your generation method is **idempotent** or handles partial failures gracefully.
:::

---

## Built-in Download Endpoints

The BIA framework ships a `FilesController` that exposes two endpoints. These are already wired up in the framework and require no additional code in your project.

### `GET /api/files/{guid}/getdownloadtoken`

Returns a single-use download token for the file identified by `{guid}`.

- **Authentication**: Required (the user must be authenticated).
- **Authorization**: The service verifies that the requesting user is the same one who originally requested the file.
- **Response**: `200 OK` with the token string, or `404 Not Found` if the file data is not found.

### `GET /api/files/{guid}/download?token={token}`

Downloads the file. This endpoint is **anonymous** because the token itself acts as the authorization proof.

- **Authentication**: None (anonymous).
- **Validation**: The token must be valid and unused.
- **Response**: `200 OK` with the file stream, or `404 Not Found` if the token is invalid or expired.

:::tip
The typical front-end flow is:
1. User clicks the download notification.
2. Front calls `GET /api/files/{guid}/getdownloadtoken` (authenticated) to obtain a token.
3. Front navigates to `GET /api/files/{guid}/download?token=...` to trigger the browser download (can be a direct `<a href>` or `window.open`).

Because step 3 is anonymous, the browser can open it as a direct link without passing the Bearer token in the URL.
:::

---

## `FileDownloadDataDto` Reference

| Property | Type | Description |
|---|---|---|
| `FileName` | `string` | The name the downloaded file will have in the browser. |
| `FileContentType` | `string` | MIME type (e.g., `application/pdf`, `text/csv`). |
| `FilePath` | `string` | Absolute path to the generated file on disk. |
| `AvailabilityDuration` | `TimeSpan?` | Optional but **strongly recommended**. How long the file remains available after it is notified. `null` means no expiry — the file and its database record will remain indefinitely until manually removed. |
| `RequestByUser` | `OptionDto` | Set automatically by the service. Do not set manually. |
| `RequestDateTime` | `DateTime` | Set automatically by the service. Do not set manually. |

Always use the static `Create()` factory method to build the DTO — **never instantiate `FileDownloadDataDto` directly**:

```csharp
var dto = FileDownloadDataDto.Create(
    fileName:             "export.csv",
    fileContentType:      "text/csv; charset=utf-8",
    filePath:             "/app/fileserver/export.csv",
    availabilityDuration: TimeSpan.FromMinutes(30));
```

:::warning
`fileContentType` must be a **valid HTML MIME type** recognized by the browser (e.g., `application/pdf`, `text/csv; charset=utf-8`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`). An incorrect or missing MIME type may cause the browser to mishandle the download or display the file inline instead of saving it. Refer to the [MDN common MIME types list](https://developer.mozilla.org/en-US/docs/Web/HTTP/MIME_types/Common_types) for a complete reference.
:::

:::warning
`AvailabilityDuration` is measured from the moment `NotifyDownloadReadyAsync` is called. If the user tries to download an expired file, a `FrontUserException` is thrown and the file is automatically deleted from disk and from the database.
:::

---

## Cleaning Up Files

Files and their database records are removed in the following situations:

| Situation | Trigger | Behavior |
|---|---|---|
| File has expired | User tries to download it | File and DB record are deleted; a `FileToDownloadExpired` error is returned to the front-end. |
| Scheduled cleanup | `CleanFileDownloadDataTask` (built-in recurring Hangfire job) | All expired entries are queried and `RemoveFileToDownload` is called on each one automatically. |
| Manual cleanup | Call `RemoveFileToDownload` directly | Deletes the DB record, optionally the associated notification, and the file on disk. |

### Automatic cleanup – `CleanFileDownloadDataTask`

The BIA framework ships a built-in Hangfire task, `CleanFileDownloadDataTask`, that automatically deletes all `FileDownloadData` entries whose availability duration has elapsed. This task is registered as a **recurring Hangfire job in the `DeployDB` project**:

```csharp title="DeployDB/Program.cs"
RecurringJob.AddOrUpdate<CleanFileDownloadDataTask>(
    $"{projectName}.{typeof(CleanFileDownloadDataTask).Name}",
    t => t.Run(),
    configuration["Tasks:CleanFileDownloadData:CRON"]);
```

The CRON expression is read from the `appsettings.json` of the `DeployDB` project and defaults to **every hour** (`0 * * * *`):

```json title="DeployDB/appsettings.json"
{
  "Tasks": {
    "CleanFileDownloadData": {
      "CRON": "0 * * * *"
    }
  }
}
```

:::tip
You can adjust the cleanup frequency by overriding this value in the environment-specific `appsettings` file of the `DeployDB` project (e.g., `appsettings.Production.json`).
:::

### Manual cleanup

```csharp
// Delete the file, its DB record, and optionally the associated notification
await this.fileDownloaderService.RemoveFileToDownload(
    fileDownloadData,
    deleteAssociatedNotification: true);
```

---

## Notification Translations

The `DownloadReady` notification is automatically created with translations in **French**, **English**, and **Spanish**. The language IDs are configured via your project's `FileDownloaderOptions` (see [Configuration](#configuration)).

To support additional languages or change the notification content, see [Extending the Service](#extending-the-service).

---

## Extending the Service

Because `BiaFileDownloaderOptions` and `BiaFileDownloaderService` are both **abstract**, every project **must** provide concrete subclasses. The base classes cannot be instantiated or registered directly — subclassing is a required step, not optional customization.

### Minimal required implementation

:::info
`FileDownloaderOptions` and `FileDownloaderService` are **already provided by the BIA project template**. In a project generated from the template, these classes exist out of the box and no manual creation is required. The implementation below is shown for reference only.
:::

The simplest implementation (as used in BIADemo) consists of two classes that simply inherit from the base without adding anything:

```csharp title="Application/File/FileDownloaderOptions.cs"
public class FileDownloaderOptions : BiaFileDownloaderOptions { }
```

```csharp title="Application/File/FileDownloaderService.cs"
public class FileDownloaderService : BiaFileDownloaderService<
    FileDownloaderOptions,
    INotificationAppService,
    Notification,
    NotificationDto,
    NotificationListItemDto>
{
    public FileDownloaderService(IServiceProvider serviceProvider, ILogger<FileDownloaderService> logger)
        : base(serviceProvider, logger) { }
}
```

The constructor takes only `IServiceProvider` and `ILogger` — the base class resolves all other dependencies internally via `IServiceProvider`.

The five generic parameters of `BiaFileDownloaderService` map to:
- `TFileDownloaderOptions` — your options subclass
- `TINotificationAppService` — the notification application service interface
- `TNotification` — the notification entity
- `TNotificationDto` — the notification DTO
- `TNotificationListItemDto` — the notification list-item DTO

The notification types must match the concrete types already registered in your project for the notification feature.

### Adding Translations for Additional Languages

All service methods are `virtual`, allowing you to override any part of the behaviour. The translation-related methods — `GetNotificationTranslations` and `CreateDownloadReadyNotification` — are `protected virtual` and are the primary extension points.

By default the service creates `DownloadReady` notification translations in French, English, and Spanish. Here is how to add support for German as an example.

**Step 1 – Extend the options class** to add the extra language ID:

```csharp title="Application/File/MyFileDownloaderOptions.cs"
public class MyFileDownloaderOptions : BiaFileDownloaderOptions
{
    public int GermanLanguageId { get; set; }
}
```

**Step 2 – Inherit the service** and override `GetNotificationTranslations`:

```csharp title="Application/File/MyFileDownloaderService.cs"
public class MyFileDownloaderService : BiaFileDownloaderService<
    MyFileDownloaderOptions,
    INotificationAppService,
    Notification,
    NotificationDto,
    NotificationListItemDto>
{
    public MyFileDownloaderService(IServiceProvider serviceProvider, ILogger<MyFileDownloaderService> logger)
        : base(serviceProvider, logger) { }

    protected override List<NotificationTranslationDto> GetNotificationTranslations(string fileName)
    {
        // Start from the default translations (EN, FR, ES) and append the new one
        var translations = base.GetNotificationTranslations(fileName);

        translations.Add(new NotificationTranslationDto
        {
            LanguageId = this.Options.GermanLanguageId,
            Title = "Download bereit",
            Description = $"Ihre Datei '{fileName}' kann heruntergeladen werden.",
            DtoState = DtoState.Added,
        });

        return translations;
    }
}
```

**Step 3 – Update the IoC registration** to use your custom types:

```csharp title="Crosscutting.Ioc/IocContainer.cs"
param.Collection.Configure<MyFileDownloaderOptions>(options =>
{
    options.FrenchLanguageId  = LanguageId.French;
    options.EnglishLanguageId = LanguageId.English;
    options.SpanishLanguageId = LanguageId.Spanish;
    options.GermanLanguageId  = LanguageId.German;  // your project's language ID
});

param.Collection.AddTransient<IFileDownloaderService, MyFileDownloaderService>();
```

:::tip
The same pattern applies to any other customization: override `CreateDownloadReadyNotification` to change the notification structure itself (type, recipients, JData…), or any other `virtual` method to alter the service behaviour entirely.
:::

---

## Front-end: Triggering the Download from Angular

The BIA framework provides an Angular service, `BiaFileDownloaderService`, that handles the two-step token + download flow described in [Built-in Download Endpoints](#built-in-download-endpoints). It is `providedIn: 'root'` and requires no additional module registration.

### What `downloadFile` does

```typescript
public downloadFile(guid: string, onComplete?: () => void): void
```

1. Calls `GET /api/files/{guid}/getdownloadtoken` (authenticated) to obtain a single-use token.
2. Opens `GET /api/files/{guid}/download?token={token}` in a new browser tab via `window.open`, which triggers the native browser download.
3. Calls the optional `onComplete` callback once the sequence finishes (whether successfully or after an error).

:::info
The download URL is opened anonymously in a new tab. This means the user's authentication token is **not** sent for the actual file transfer — the single-use token returned by step 1 acts as the proof of identity. This is what allows the browser to download the file without any special HTTP header handling.
:::

### Built-in usage: inside the BIA notification workflow

The BIA framework already calls `downloadFile` automatically when the user interacts with a `DownloadReady` notification — either from the **toast** (topbar) or from the **notification detail** view. No additional code is required on your side for this standard workflow.

The notification's `JData` carries a `downloadFileGuid` field. When detected, the framework calls:

```typescript
this.fileDownloaderService.downloadFile(data.downloadFileGuid);
```

### Manual usage: calling `downloadFile` outside the notification workflow

If you need to trigger the download from your own component — for example, from a button in a custom view that already knows the file GUID — inject `BiaFileDownloaderService` and call `downloadFile` directly:

```typescript title="app/features/reports/components/report-list.component.ts"
import { Component, inject } from '@angular/core';
import { BiaFileDownloaderService } from 'packages/bia-ng/core/public-api';

@Component({ /* ... */ })
export class ReportListComponent {
  private fileDownloaderService = inject(BiaFileDownloaderService);

  // isDownloading can be bound to a loading spinner or used to disable the button
  protected isDownloading = false;

  onDownloadClick(fileGuid: string): void {
    this.isDownloading = true;
    this.fileDownloaderService.downloadFile(fileGuid, () => {
      // onComplete callback: called after success or error
      this.isDownloading = false;
    });
  }
}
```

```html title="app/features/reports/components/report-list.component.html"
<button
  pButton
  label="Download"
  [disabled]="isDownloading"
  (click)="onDownloadClick(row.fileGuid)">
</button>
```

:::tip
Use the `onComplete` callback to reset a loading indicator or re-enable a button. It is called in the `finalize` operator, so it always runs — even if the token request fails. Errors from the API are automatically displayed to the user via `BiaMessageService`.
:::

:::warning
`downloadFile` relies on `window.open`. Some browsers may block the new tab if the call does not originate directly from a user interaction (e.g., if it is triggered inside a `setTimeout` or after a delayed observable). Always call it synchronously from a click handler to avoid pop-up blockers.
:::
