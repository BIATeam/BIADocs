---
sidebar_position: 1
---

# Back Exception Handler
This document explains how back-end exceptions can be handled through the BIA Framework.

## Configure
In the `Startup` class, within the `Configure()` method, ensure there is a call to the extension `ConfigureApiExceptionHandler()`, passing a boolean parameter to indicate whether the host environment is a development environment :

```csharp title="Startup.cs"
public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IJwtFactory jwtFactory)
{
    // ...
    app.ConfigureApiExceptionHandler(env.IsDevelopment());
    // ...
}
```

This extension adds an exception handler middleware to the `IApplicationBuilder` to catch all unhandled exceptions before returning the `HttpResponse`. An error log will be automatically created with the exception content.

If the environment is not a development environment, the `HttpStatusCode` will be set to `500`, and the `HttpResponse.Body` will be replaced with a translated internal server error message to anonymize the application's errors.

The exception handler will also handle the raised [Front User Exceptions](#front-user-exception).

## Front User Exception
This is a custom exception used to display specific details to the end user of the application according to a specific error identifier :

```csharp
public class FrontUserException : Exception
{
    /// <summary>
    /// The error message key.
    /// </summary>
    public int ErrorId { get; } = (int)BiaErrorId.Unknown;

    /// <summary>
    /// The parameters to format into the current <see cref="Exception.Message"/>.
    /// </summary>
    public string[] ErrorMessageParameters { get; } = [];
}
```
- `ErrorId` : used to identify the type of error and retrieve the corresponding translated user-friendly error message.
- `ErrorMessageParameters` : used in combination with the exception `Message` or the corresponding translated message according to the `ErrorId` to format the final user-friendly error message to be returned.
  
### Throwing
The `FrontUserException` can be thrown by various way :

```csharp
// FrontUserException with only custom message and optionnal inner exception
throw new FrontUserException("This is an error message", innerException: null);

// FrontUserException with a custom templated message and optionnal inner exception
throw new FrontUserException("This is an {0} {1}", innerException: null, "error", "message");

// FrontUserException with only error message key as int and optionnal inner exception
throw new FrontUserException((int)ErrorId.Unknown, innerException: null);

// FrontUserException with an error message key as int and parameters to fill into the templated error message and optionnal inner exception
throw new FrontUserException((int)ErrorId.Unknown, innerException: null, "param1", "param2");

// FrontUserException with only inner exception
throw new FrontUserException(new Exception("Inner exception"));

// FrontUserException with only error message key as enum and optionnal inner exception
throw FrontUserException.Create(ErrorId.CustomError, innerException: null);

// FrontUserException with an error message key as enum and parameters to fill into the templated error message and optionnal inner exception
throw FrontUserException.Create(ErrorId.CustomError, innerException: null, "param1", "param2");
```
:::tip
- Prefer to use `FrontUserException.Create(Enum.Value)` instead of `new FrontUserException((int)Enum.Value);`
- When using the constructor with only the `innerException` parameter, the exception message will be an empty string.
:::

### Catching
#### From BIA Core
The BIA Framework will throw some `FrontUserException`, allowing developers to catch them.  
Most of these exceptions are raised from the **Data layer** and handled by the **Domain layer** inside the `OperationalDomainServiceBase` class in a dedicated method `HandleFrontUserException()`.

:::info
- The purpose of this method is to analyze the content of the original `FrontUserException` coming from sub-layers and return a new one if needed
- This method can be overridden by all inherited objects from `OperationalDomainServiceBase` to allow the developer to create custom behaviors
:::

```csharp title="MyEntityAppService.cs"
public class MyEntityAppService : OperationalDomainServiceBase<MyEntity, int>
{
    // [...]

    protected override Exception HandleFrontUserException(FrontUserException frontUserException)
    {
        // CASE #1
        // Return a new FrontUserException with custom message, ignore previous exception
        return new FrontUserException("Custom message");

        // CASE #2
        // Do some actions based on the ErrorId
        if (frontUserException.ErrorId == BiaErrorId.DatabaseDuplicateKey)
        {
            // Do something...
        }
        // Return the FrontUserException handled by base service
        return base.HandleFrontUserException(frontUserException);

        // CASE #3
        // Return a new FrontUserException by specific ErrorId
        return frontUserException.ErrorId switch
        {
            BiaErrorId.DatabaseDuplicateKey => new FrontUserException("A similar {0} exists with the same value", frontUserException, nameof(MyEntity))
            _ => new FrontUserException("Application error, please contact support", frontUserException)
        };

        // CASE #4
        // Returning a null Exception will stop the catch instruction handling the original FrontUserException
        return null;
    }
}
```

#### From deeper layer
When some error information to fill in the error message template is not available in the error context, you can throw a new `FrontUserException` based on the original one in the higher call context and completing the `ErrorMessageParameters` by redefining it with the available information :

```csharp
public class DeepLayer
{
    private string DeepInformation => "something";

    public void Do()
    {
        try
        {
            // Do something
        }
        catch (Exception ex)
        {
            throw new FrontUserException("Deeper data : {0} - Higher data : {1}", ex, DeepInformation);
        }
    }
}

public class Layer
{
    private readonly DeepLayer deepLayer;
    private string LayerInformation => "nothing";

    public Layer(DeepLayer deepLayer)
    {
        this.deepLayer = deepLayer;
    }

    public void Do()
    {
        try
        {
            this.deepLayer.Do();
        }
        catch (CustomFrontUserException ex)
        {
            // Throw new FrontUserException using previous error message parameters, and complete with more error message parameters
            throw new FrontUserException(ex.Message, ex.InnerException, [.. ex.ErrorMessageParameters, this.LayerInformation]);
        }
    }
}
```
When the final `FrontUserException` thrown will be caught by the [API Exception Handler](#configure), the formatted message will be :  
**`Deeper data : something - Higher data : nothing`**

:::tip
When configuring templated error messages, ensure to provide the correct number of `ErrorMessageParameters` before the catch in the API exception handler to avoid format exceptions.
:::

### Errors identifiers
You can define your own errors into the `ErrorId` class into the `Crosscutting.Common` layer :
``` chsarp title="ErrorId.cs"
namespace TheBIADevCompany.BIADemo.Crosscutting.Common.Error
{
    /// <summary>
    /// The enumeration of all error ids.
    /// </summary>
    public enum ErrorId
    {
        /// <summary>
        /// Custom error.
        /// </summary>
        CustomError,
    }
}
```

:::info
BIA Core error identiifers are defined into the `BIA.Net.Core.Common.Error.BiaErrorId` enum :
- Values starts from `1000`
- `Unknown` value = `1000`
:::

### Errors translations
Into the `ErrorMessage` class, define the translations of your custom errors into the `Translations` collection :
``` chsarp title="ErrorMessage.cs"
namespace TheBIADevCompany.BIADemo.Crosscutting.Common.Error
{
    public static class ErrorMessage
    {
        private static readonly ImmutableList<BiaErrorTranslation> Translations =
        [
            new BiaErrorTranslation() { ErrorId = (int)ErrorId.CustomError, LanguageId = LanguageId.English, Label = "Custom error message." },
            new BiaErrorTranslation() { ErrorId = (int)ErrorId.CustomError, LanguageId = LanguageId.French, Label = "Message d’e rreur personnalisé." },
            new BiaErrorTranslation() { ErrorId = (int)ErrorId.CustomError, LanguageId = LanguageId.Spanish, Label = "Mensaje de error personalizado." },
        ];

        /// <summary>
        /// Fill the error translations.
        /// </summary>
        public static void FillErrorTranslations()
        {
            BiaErrorMessage.InitBiaErrorTranslations(LanguageId.English, LanguageId.French, LanguageId.Spanish);
            BiaErrorMessage.MergeTranslations(Translations);
        }
    }
}
```

:::info
- The `FillErrorTranslations()` is called from the `IocContainer` when application is building at startup
- Add the language identifiers for **English**, **French** and **Spanish** (if using them) as parameters of the `BiaErrorMessage.InitBiaErrorTranslations()` method
- The `BiaErrorMessage.MergeTranslations()` method merge your own `Translations` with the `Translations` of core errors defined into the `BiaErrorMessage` class 
:::
:::tip
You can retrieve the translated message of an error by using the method `BiaErrorMessage.GetMessage()` :
- `BiaErrorMessage.GetMessage(Enum.Value, languageId)` : when using direct `Enum` values
- `BiaErrorMessage.GetMessage(errorId, languageId)` : when using error identifier as `int`
:::

### Working with ApiExceptionHandler
When a `FrontUserException` is thrown, the [API Exception Handler](#configure) will automatically handle it.  

The `HttpResponse` will be modified :
- `HttpStatusCode` will be set to `422` (Unprocessable Entity)
- `HttpResponse` transformed as a `HttpErrorReport`

``` chsarp title="HttpErrorReport.cs"
namespace BIA.Net.Core.Presentation.Api
{
    /// <summary>
    /// Represents a HTTP error report.
    /// </summary>
    /// <param name="ErrorCode">The error code.</param>
    /// <param name="ErrorMessage">The error message.</param>
    public record class HttpErrorReport(int ErrorCode,  string ErrorMessage)
    {
    }
}
```
- `ErrorCode` : the error identifier of the `FrontUserException`
- `ErrorMessage` : formated and translated message from the `FrontUserException`

:::tip
- In a web application with a front end, the BIA Framework Angular will display an error pop-up with the error message.
- If the exception message is null or empty, the `ErrorMessage` will contain the base exception message of the inner exception. For anonymization purposes, if the environment is not a development environment, the message will be a translated internal servor error message.
:::

### Handle in Front-End
Once your `FrontUserException` with corresponding error identifiers set, you can handle them into the front-end to execute some actions when an error occurs with a specific error code.  

Into your feature effects `catchError()`, simply use the `isHttpErrorReport()` to convert the `HttpErrorResponse` as `HttpErrorReport` (if applicable), and use then the `errorCode` :
``` typescript title="my-entities-effects.ts"
export class MyEntitiesEffects {
  effect$ = createEffect(() =>
    this.actions$.pipe(
      ofType(FeatureMyEntitiesActions.effect),
      map(x => x?.id),
      switchMap(id => {
        return this.myEntityDas.effect({ id: id }).pipe(
          map(myEntity => {
            return FeatureMyEntitiesActions.effectSuccess({ myEntity });
          }),
          catchError(err => {
            this.biaMessageService.showErrorHttpResponse(err);
            // Verify here if the error is HttpErrorReport
            if(isHttpErrorReport(err)) {
                // Check errorCode to do some actions
                switch (err.errorCode) {
                    // [...]
                }
            }
            return of(FeatureMyEntitiesActions.failure({ error: err }));
          })
        );
      })
    )
  );
}
```