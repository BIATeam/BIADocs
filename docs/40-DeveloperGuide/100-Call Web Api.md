---
sidebar_position: 1
---

# Call Web Api

This file explains how to call a web api from the backend in your V3 project.

## Implementation

Edit your **appsettings.json** files for each environment to fill in the base url of the web api you want to call.
Example:

```json
"WebApiName": {
    "baseAddress": "https://hostWebApi.domainWebApi/WebApiName/WebApi"
  },
```

Create a new class ***YourRepositoryName*****Repository.cs** in the **Repositories** folder of the **Infrastructure.Service** project.
Inherit this class from the **WebApiRepository** abstract class.

Here an example implementation:

- The first method shows an example of a GET call with date type input parameters.
- The second method shows an example POST call. Sometimes the input parameters are too complex for a GET. It is then necessary to use a POST.
- The different Dtos must be created in the **Domain.Dto** project

```csharp
    public class YourRepositoryNameRepository : WebApiRepository, IYourRepositoryNameRepository
    {
        public YourRepositoryNameRepository(HttpClient httpClient, IConfiguration configuration, ILogger<YourRepositoryNameRepository> logger)
            : base(httpClient, logger)
        {
            this.BaseAddress = configuration.GetSection("WebApiName")["baseAddress"];
        }

        public async Task<List<YourOutputNameDto>> GetAsync(string name, DateTime beginDate, DateTime endDate)
        {
            if (!string.IsNullOrWhiteSpace(name) && beginDate != default(DateTime) && endDate != default(DateTime))
            {
                string sBeginDate = beginDate.Date.ToString(FormatDate);
                string sEndDate = endDate.Date.ToString(FormatDate);

                string queryParam = $"byParams?name={name}&beginDate={sBeginDate}&endDate={sEndDate}";
                string url = this.BaseAddress + queryParam;

                return (await this.GetAsync<List<YourOutputNameDto>>(url)).Result;
            }

            return null;
        }

        public async Task<List<YourOutputNameDto>> GetAsync(string name, List<YourInputNameDto> inputs)
        {
            if (!string.IsNullOrWhiteSpace(name) && inputs?.Any() == true)
            {
                string queryParam = $"byParams?name={name}";
                string url = this.BaseAddress + queryParam;

                return (await this.PostAsync<List<YourOutputNameDto>, List<YourInputNameDto>>(url, inputs)).Result;
            }

            return null;
        }
    }
```

Generate the corresponding interface, **IYourRepositoryNameRepository**

```csharp
public interface IYourRepositoryNameRepository
{
    Task<List<YourOutputNameDto>> GetAsync(string name, DateTime beginDate, DateTime endDate);
    Task<List<YourOutputNameDto>> GetAsync(string name, List<YourInputNameDto> inputs);
}
```

and add it in **Domain** project, **RepoContract** folder.

In the **Crosscutting.Ioc.IocContainer** class, modify the **ConfigureInfrastructureServiceContainer** method by adding:

```csharp
collection.AddTransient<IYourRepositoryNameRepository, YourRepositoryNameRepository>();
```

Add the repository in the constructor of a service so that it is injected and use it in a method

```csharp
private readonly IYourRepositoryNameRepository yourRepositoryNameRepository;

public YourServiceNameAppService(IYourRepositoryNameRepository yourRepositoryNameRepository)
{
    this.yourRepositoryNameRepository = yourRepositoryNameRepository;
}

async Task GetAsync()
{
    string name = "random";
    DateTime beginDate = DateTime.Today;
    DateTime endDate = DateTime.Today.AddDays(20);

    List<YourOutputNameDto> dtos = await this.yourRepositoryNameRepository.GetAsync(name, beginDate, endDate);
}
```

## Bearer Token

Since version 3.7, you can pass a token to your requests. To do this, you must set the **useBearerToken** input parameter to **true** and override the **GetBearerTokenAsync()** method.

You will find an example of implementation in class

**TheBIADevCompany.BIADemo.Infrastructure.Service.Repositories.RemotePlaneRepository**

and in class

**TheBIADevCompany.BIADemo.Infrastructure.Service.Repositories.IdentityProviderRepository**

## Retry

Sometimes, when an error occurs when calling a WebApi, we need to try again. The framework >= 3.8 implements Retry functionality by default (The retry is only executed once). Retry is based on a method that checks the retry conditions. Below is the default code. If the conditions do not suit you, you can change them by **override**.

```csharp
 protected virtual bool CheckConditionRetry(HttpResponseMessage response, bool useBearerToken)
 {
     return useBearerToken &&
         (response.StatusCode == System.Net.HttpStatusCode.Forbidden ||
         response.StatusCode == System.Net.HttpStatusCode.Unauthorized ||
         (int)response.StatusCode == 498); // Token expired/invalid
 }
```
