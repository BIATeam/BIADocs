---
sidebar_position: 101
---

# Calling a BIA application Web API from backend

This guide explains how to call another BIA application from the backend using two specialized repositories:

- `BIA.Net.Core.Infrastructure.Service.Repositories.BiaApi.BiaWebApiRepository` — for calling API controllers protected by Windows or Keycloak auth, using policies configured in the target app.
- `BIA.Net.Core.Infrastructure.Service.Repositories.BiaApi.BiaWebApiJwtRepository` — for calling API controllers that require an application JWT (fine‑grained permissions similar to the Angular front).

Both repositories automatically detect if the remote API uses Windows or Keycloak authentication. You don’t need to handle that yourself.

## When to use which repository

- Use `BiaWebApiRepository` when the target API controllers are protected by auth (Windows or Keycloak) and authorize access via Policies in the target app.
  - Example: calling controllers derived from `TheBIADevCompany.BIADemo.Presentation.Api.Controllers.Bia.Base.ServiceApiRwController` with policy `ServiceApiRW`.
- Use `BiaWebApiJwtRepository` when you need application JWT to get fine‑grained rights, mirroring front-end behavior. In this case, you will need to grant permissions to the service account in the API called.
  - Example: remote CRUD or operations where the app’s own JWT is required.

## Configuration in caller app

Add a section in your `appsettings.json` providing the remote API configuration:

```json
"MyBiaWebApi": {
  "BaseAddress": "https://remote-host/api",
  "UseLoginFineGrained": true,
  "CredentialSource": {
    "VaultCredentialsKey": "VaultName"
  }
}
```

- `BaseAddress`: base URL of the remote BIA API.
- `UseLoginFineGrained` (for `BiaWebApiJwtRepository`): if true, the repository performs a login to get a JWT with fine‑grained rights; otherwise it fetches a token.
- `CredentialSource`: optional source to obtain credentials when the target is in Keycloak mode.

Policies in the remote API are configured in its `BiaNetSection`:

```json
"Policies": [
  {
    "Name": "ServiceApiRW",
    "RequireClaims": [
      {
        "Type": "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
        "AllowedValues": ["S-1-5-21-3284204050-131030045-1404716486-989788"] // AD group sid
      }
    ]
  }
]
```

In the remote API, controllers can enforce that policy via `ServiceApiRwController`:

- `TheBIADevCompany.BIADemo.Presentation.Api.Controllers.Bia.Base.ServiceApiRwController` applies `[Authorize(Policy = BiaConstants.Policy.ServiceApiRW)]`.

## How automatic auth detection works

- `BiaWebApiRepository` calls the remote `"/api/AppSettings"` to learn whether Keycloak is active (`Keycloak.IsActive`).
- If Keycloak is active, the repository switches to token mode and obtains a bearer via `BiaKeycloakHelper`.
- If not active, it uses anonymous/Windows auth (with Negotiate) depending on the remote server setup.
- Bearer tokens are cached per `BaseAddress` and refreshed as needed.

`BiaWebApiJwtRepository` always uses token mode and delegates authentication to `IBiaWebApiAuthRepository`:
- If `UseLoginFineGrained` is true, it calls `LoginAsync` (remote `GET /api/Auth/login?lightToken=false`).
- Otherwise, it calls `GetTokenAsync` (remote `GET /api/Auth/token`).

You do not need to directly use `BiaWebApiAuthRepository` in your code.

## Example usages in BIADemo

- `TheBIADevCompany.BIADemo.Infrastructure.Service.Repositories.RemoteBiaApiRwRepository` uses `BiaWebApiRepository` to ping the remote API:
  - It loads `MyBiaWebApi` from configuration and calls `GET {BaseAddress}/api/Auth/token`.
- `TheBIADevCompany.BIADemo.Infrastructure.Service.Repositories.RemotePlaneRepository` uses `BiaWebApiJwtRepository` to manage planes on a remote BIA app:
  - It maps domain entities to DTOs and calls `GET/POST/PUT/DELETE` under `"/api/Planes"` using the application JWT.

BIADemo controller demonstrating these services:
- `TheBIADevCompany.BIADemo.Presentation.Api.Controllers.Utilities.BiaRemoteController` exposes endpoints:
  - `GET /utilities/biaremote/ping` calls `IRemoteBiaApiRwService.PingAsync()`.
  - `GET /utilities/biaremote/planes/{id}` checks remote plane existence via `IRemotePlaneAppService`.
  - `POST /utilities/biaremote/planes/test` creates a remote plane.

## Implementing your repository

1. Choose the base class:
   - `BiaWebApiRepository` for policy/role protected endpoints on the remote.
   - `BiaWebApiJwtRepository` for endpoints requiring application JWT.
2. Create your repository in your `Infrastructure.Service` project’s `Repositories` folder.
3. Inject `HttpClient`, `ILogger<T>`, and `IBiaDistributedCache`.
   - For `BiaWebApiJwtRepository`, also inject `IBiaWebApiAuthRepository` and pass `configuration.GetSection("MyBiaWebApi").Get<BiaWebApi>()` to the base constructor.
4. Build URLs using `BaseAddress` and your resource paths.
5. Call method as needed.

## Dependency Injection registration

Register HTTP clients and repositories in your IoC container, for example:

- For `BiaWebApiRepository` implementations:
  - `collection.AddHttpClient<IRemoteBiaApiRwRepository, RemoteBiaApiRwRepository>()...`
- For `BiaWebApiJwtRepository` implementations:
  - `collection.AddHttpClient<IRemotePlaneRepository, RemotePlaneRepository>()...`

Use the existing `BiaIocContainer.CreateHttpClientHandler(biaNetSection)` when configuring the primary handler.

## Common patterns and tips

- Always use `BaseAddress` from the configuration injected into the repository.
- Let the repository handle bearer token acquisition; don’t manually attach Authorization headers.
- For fine‑grained rights, ensure the remote app’s roles/policies match your expected permissions.
- Prefer DTOs for payloads and responses; keep domain entities decoupled from transport.
- Retry is built into `WebApiRepository` for token scenarios (Forbidden/Unauthorized/498). You can override the retry condition if needed.

## References

- Classes:
  - `BIA.Net.Core.Infrastructure.Service.Repositories.BiaApi.BiaWebApiRepository`
  - `BIA.Net.Core.Infrastructure.Service.Repositories.BiaApi.BiaWebApiJwtRepository`
  - `TheBIADevCompany.BIADemo.Infrastructure.Service.Repositories.RemoteBiaApiRwRepository`
  - `TheBIADevCompany.BIADemo.Infrastructure.Service.Repositories.RemotePlaneRepository`
  - `TheBIADevCompany.BIADemo.Presentation.Api.Controllers.Bia.Base.ServiceApiRwController`
  - `TheBIADevCompany.BIADemo.Presentation.Api.Controllers.Utilities.BiaRemoteController`
- Configuration helpers:
  - `BIA.Net.Core.Presentation.Api.StartupConfiguration.AuthenticationConfiguration`
  - `BIA.Net.Core.Common.Configuration.Policy`
  - `BIA.Net.Core.Common.Configuration.RequireClaim`
