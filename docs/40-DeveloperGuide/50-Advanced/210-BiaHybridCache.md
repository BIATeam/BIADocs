---
sidebar_position: 210
---

# BiaHybridCache Usage Guide

## Overview
`BiaHybridCache` implements `IBiaHybridCache` to provide a hybrid cache abstraction over distributed and local cache layers using `Microsoft.Extensions.Caching.Hybrid.HybridCache`. It is based on the ASP.NET Core HybridCache library: https://learn.microsoft.com/en-us/aspnet/core/performance/caching/hybrid?view=aspnetcore-10.0.

Key behaviors:
- Tags and team identifiers are used for targeted invalidation and grouping.
- Local and distributed cache layers can be enabled or disabled via configuration or per-call overrides.

## Interface
`IBiaHybridCache` exposes the following operations:
- `GetOrCreateAsync<T>(...)`: fetches or builds a cached value.
- `RemoveAsync(...)`: removes a specific cache entry by key.
- `RemoveAllAsync(...)`: clears all entries managed by this cache.
- `RemoveByTeamIdAsync(...)`: clears entries for a specific team scope.
- `RemoveByTagAsync(...)`: clears entries with matching tags.

## Configuration
The defaults come from `BIA.Net.Core.Common.Configuration.CommonFeature.HybridCacheConfiguration` and the `BiaNet` section of `bianetconfig.json`.

### Configuration types
`BIA.Net.Core.Common.Configuration.CommonFeature.HybridCacheConfiguration`:
- `ExpirationSeconds`: default distributed cache expiration.
- `LocalCacheExpirationSeconds`: default local cache expiration.

### Configuration file
Example `bianetconfig.json`:
```json
{
  "BiaNet": {
    "CommonFeatures": {
      "DistributedCache": {
        "IsActive": true,
        "ConnectionStringName": "ProjectDatabase"
      },
      "HybridCache": {
        "ExpirationSeconds": 600,
        "LocalCacheExpirationSeconds": 100
      }
    }
  }
}
```

### Default behavior
- If `ExpirationSeconds` is missing, distributed cache defaults to 300 seconds.
- If `LocalCacheExpirationSeconds` is missing, local cache defaults to 5 seconds.
- Setting either expiration to `0` disables that cache layer.
- If `DistributedCache:IsActive` is `false`, only the local cache is used.

## Usage examples

### Getting an instance
```csharp
public class MyAppService
{
    private readonly IBiaHybridCache hybridCache;

    public MyAppService(IBiaHybridCache hybridCache)
    {
        this.hybridCache = hybridCache;
    }
}
```

### Basic GetOrCreate
```csharp
var result = await hybridCache.GetOrCreateAsync(
    ct => this.GetByMyBusinessRuleAsync(param1, param2, param3),
    teamId: 42,
    tags: new List<string> { "planes", "engine" });
```

### Override expirations per call
```csharp
var result = await hybridCache.GetOrCreateAsync(
    ct => this.GetByMyBusinessRuleAsync(param1, param2, param3),
    expiration: TimeSpan.FromMinutes(10),
    localCacheExpiration: TimeSpan.FromSeconds(30));
```

### Provide an explicit key
```csharp
var result = await hybridCache.GetOrCreateAsync(
    ct => this.GetByMyBusinessRuleAsync(param1, param2, param3),
    key: "MyCustomKey");
```

### Remove entries
```csharp
await hybridCache.RemoveAsync("MyCustomKey");
await hybridCache.RemoveByTeamIdAsync(42);
await hybridCache.RemoveByTagAsync("planes");
await hybridCache.RemoveByTagAsync(new List<string> { "planes", "engine" });
await hybridCache.RemoveAllAsync();
```

## Tag and team behavior
- `teamId` scopes cached values to a team. Use the same `teamId` in all calls that should share data, and use `RemoveByTeamIdAsync` to invalidate all entries for that team.
- Tags allow grouping cache entries by feature or data domain. Use `RemoveByTagAsync` (single tag) or `RemoveByTagAsync(List<string>)` (multiple tags) to invalidate the grouped entries.
- When you pass tags, the cache stores them internally with a `Tag:` prefix. Pass raw tag names only (for example: `"planes"`, not `"Tag:planes"`).

