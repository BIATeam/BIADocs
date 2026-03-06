---
sidebar_position: 1
---

# Creating Custom Message Types for IframeCommunicationService

This guide explains how to create and register new message types in the `IframeCommunicationService`. This service enables secure cross-iframe communication by providing a type-safe handler registration pattern.

## Overview

The `IframeCommunicationService` uses a handler-based architecture where:

- Each message type has a corresponding TypeScript interface
- A service registers handlers that process specific message types
- Messages are validated against security policies before processing

## Architecture

### Core Components

1. **IframeMessage** - Base interface for all message types

   ```typescript
   export interface IframeMessage {
     type: string;
   }
   ```

2. **MessageHandler** - Internal handler definition

   ```typescript
   interface MessageHandler<T extends IframeMessage> {
     typeGuard: (message: IframeMessage) => message is T; // TypeScript type guard
     processor: MessageProcessor<T>; // Handler function
   }
   ```

3. **MessageProcessor** - Handler function signature
   ```typescript
   type MessageProcessor<T extends IframeMessage> = (message: T) => void;
   ```

## Step-by-Step Guide: Creating a New Message Type

### Step 1: Define the Message Interface

Create a new interface that extends `IframeMessage`. The `type` property must be a literal string that uniquely identifies this message type.

**File:** `src/app/models/iframe-change-site-message.ts`

```typescript
import { IframeMessage } from 'packages/bia-ng/models/public-api';

export interface IframeChangeSiteMessage extends IframeMessage {
  type: 'CHANGE_TEAM';
  siteUniqueIdentifier: number;
  siteName: string;
}
```

### Step 2: Create a Message Handler Service

Create a service that registers and handles this message type. Follow the existing pattern used in `IframeConfigMessageService`.

**File:** `src/app/shared/services/iframe/iframe-change-team-message.service.ts`

```typescript
import { Injectable } from '@angular/core';
import { IframeChangeTeamMessage } from 'src/app/models/iframe-change-team-message';
import { IframeCommunicationService } from 'packages/bia-ng/shared/services/public-api';
import { AuthService } from 'packages/bia-ng/core/public-api';
import { BiaTeamTypeId } from 'packages/bia-ng/models/enum/public-api';

@Injectable({
  providedIn: 'root',
})
export class IframeChangeTeamMessageService {
  constructor(
    protected readonly iframeCommunicationService: IframeCommunicationService,
    protected readonly authService: AuthService
  ) {}

  /**
   * Registers the handler for CHANGE_TEAM messages
   * Call this method during application initialization
   */
  register() {
    this.iframeCommunicationService.registerHandler(
      'CHANGE_TEAM',
      this.handleChangeTeam.bind(this)
    );
  }

  /**
   * Processes incoming CHANGE_TEAM messages
   * @param message The CHANGE_TEAM message from parent iframe
   */
  private handleChangeTeam(message: IframeChangeSiteMessage) {
    console.log(
      `Changing site to: ${message.siteName} (Unique ID: ${message.siteUniqueIdentifier})`
    );
    // Find the site by its unique identifier to get the site ID
    const site = this.appSettingsService.appSettings?.teams?.find(
      s => s.uniqueIdentifier === message.siteUniqueIdentifier
    );
    if (site && site.id) {
      this.authService.changeCurrentTeamId(BiaTeamTypeId.Site, site.id);
    } else {
      console.error(
        `Site with unique identifier ${message.siteUniqueIdentifier} not found`
      );
    }
    // Perform additional operations as needed
  }
}
```

### Step 3: Register the Handler During Application Initialization

Register the message handler in your application's initialization flow (typically in `AppComponent` or during module setup).

**File:** `src/app/app.component.ts`

```typescript
import { IframeChangeSiteMessageService } from 'src/app/shared/services/iframe/iframe-change-site-message.service';

export class AppComponent implements OnInit {
  constructor(
    // ... other dependencies
    private iframeChangeSiteMessageService: IframeChangeSiteMessageService
  ) {}

  ngOnInit() {
    // Register iframe message handlers
    this.iframeChangeSiteMessageService.register();
    // ... other initialization code
  }
}
```

## Sending Messages from Parent Iframe

From the parent window/iframe, send messages to the embedded iframe:

```typescript
// Parent application
const childFrame = document.getElementById('myIframe') as HTMLIFrameElement;

const message: IframeChangeSiteMessage = {
  type: 'CHANGE_TEAM',
  siteUniqueIdentifier: 42,
  siteName: 'Engineering Site',
};

childFrame.contentWindow?.postMessage(message, 'https://child-domain.com');
```

## Security Considerations

### Allowed Hosts Validation

The `IframeCommunicationService` validates messages against a whitelist of allowed origins defined in application settings. This is a critical security measure that prevents malicious scripts from other domains from sending messages to your iframe.

#### How Validation Works

When a message is received, the service checks if the message's origin (the domain it came from) exists in the list of allowed hosts. If the origin is not in the whitelist, the message is silently rejected and not processed:

```typescript
// From IframeCommunicationService.readMessage()
if (
  !this.appSettingsService.appSettings?.iframeConfiguration?.allowedIframeHosts?.find(
    allowedHost => allowedHost.url === message.origin
  )
) {
  return; // Message rejected if origin not in whitelist
}
```

This prevents unauthorized applications from communicating with your iframe, protecting against potential security vulnerabilities.

#### Configuration in Backend

The allowed hosts are configured in your backend settings using the following C# classes:

```csharp
    /// <summary>
    /// Configuration when front being displayed inside an Iframe.
    /// </summary>
    public class IframeConfiguration
    {
        /// <summary>
        /// Gets or sets the configuration to allow to keep the front layout while being displayed in a iframe.
        /// </summary>
        public bool KeepLayout { get; set; }

        /// <summary>
        /// Gets or sets the allowed host for iframe communication.
        /// </summary>
        public List<AllowedHost> AllowedIframeHosts { get; set; }
    }

    /// <summary>
    /// Represents an authorized host that is allowed to communicate with this iframe.
    /// </summary>
    public class AllowedHost
    {
        /// <summary>
        /// Gets or sets the Label.
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the code culture.
        /// </summary>
        public string Url { get; set; }
    }
```

**The `AllowedHost` class contains:**
- **Name**: A human-readable label for the allowed host (e.g., "Parent Admin Portal")
- **Url**: The origin URL that is permitted to send messages (e.g., "https://admin.example.com")

**Ensure your parent iframe origin is added to:**
- `bianetconfig.iframeConfiguration.allowedIframeHosts`