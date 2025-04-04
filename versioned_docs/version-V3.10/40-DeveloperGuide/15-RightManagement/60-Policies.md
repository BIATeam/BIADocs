---
sidebar_position: 1
---

# Documentation on "Policies" Configuration

"Policies" allows you to control access to your application based on the "Claims" held in each user's authentication token.

## Understanding the Configuration File

The configuration file for "Policies" typically takes the following structure:

```json
"Policies": [
  {
    "Name": "ServiceApiRW",
    "RequireClaim": {
      "Type": "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
      "AllowedValues": [ "S-1-5-21-3284204050-131030045-1404716486-888888" ]
    }
  }
]
```

Each item in the "Policies" array contains details of a specific policy:

- `"Name"`: Unique name of the policy.
- `"RequireClaim.Type"`: Type of "Claim" to check. Here, the type is a user's Active Directory group ID.
- `"RequireClaim.AllowedValues"`: List of allowed values for the specific "Claim".

In this example, the policy named "ServiceApiRW" will only authorize users that carry a "Claim" of type "GroupSID" with the specified value.

## How to Modify the Configuration File

To adjust access level or to add a new policy, you need to modify the configuration file. For example, to add a new policy "ServiceApiRO" (Read-Only), you can add:

```json
"Policies": [
  {
    "Name": "ServiceApiRW",
    "RequireClaim": {
      "Type": "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
      "AllowedValues": [ "S-1-5-21-3284204050-131030045-1404716486-888888" ]
    }
  },
  {
    "Name": "ServiceApiRO",
    "RequireClaim": {
      "Type": "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
      "AllowedValues": [ "S-1-5-21-3284204050-131030045-1404716486-999999" ]
    }
  }
]
```
In this case, a new policy, "ServiceApiRO", is added. Users with the specified "GroupSID" have read-only access to the API. 

Please note that adding or modifying "Policies" in the configuration file does not involve changes to your application code. The use of "Policies" provides flexibility in authorization without touching the source code of your application.

## Applying "Policies" in Controllers 

In your C# .NET Core code, you use the `Authorize` attribute to apply a policy to a controller or an action in a controller. Here's an example:

```csharp
[Authorize(Policy = "ServiceApiRW")]
public abstract class ServiceApiRwController : BiaControllerBaseNoToken
{
}
```
In this example, the `ServiceApiRW` policy is applied to the `ServiceApiRwController` through the `Authorize` attribute. This means that to access any action within this controller, the user's "Claim" must pass the requirements specified in the `ServiceApiRW` policy. If the user lacks the necessary claim or value, they are denied access.