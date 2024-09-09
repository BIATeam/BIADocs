---
sidebar_position: 1
---

# Back Exception Handler
This document explains how back-end exceptions can be handled through the BIA Framework.

## Configure API Exception Handler
In the **Startup** class, within the **Configure** method, ensure there is a call to the extension **ConfigureApiExceptionHandler**, passing a boolean parameter to indicate whether the host environment is a development environment :

```csharp
public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IJwtFactory jwtFactory)
{
	// ...
	app.ConfigureApiExceptionHandler(env.IsDevelopment());
	// ...
}
```

This extension adds an exception handler middleware to the **IApplicationBuilder** to catch all unhandled exceptions before returning the **HttpResponse**. An error log will be automatically created with the exception content.

If the environment is not a development environment, the **HttpStatusCode** will be set to **500**, and the **HttpResponse.Body** will be replaced with an "Internal server error" message to anonymize the application's errors.

## FrontUserException
This is a custom exception used to display specific details to the end user of the application :

```csharp
public class FrontUserException : Exception
{
	/// <summary>
	/// The error message key.
	/// </summary>
	public FrontUserExceptionErrorMessageKey ErrorMessageKey { get; } = FrontUserExceptionErrorMessageKey.Unknown;

	/// <summary>
	/// The parameters to format into the current <see cref="Exception.Message"/>.
	/// </summary>
	public string[] ErrorMessageParameters { get; } = [];
}
```

An **ErrorMessageKey** is used to identify the type of error and retrieve the corresponding user-friendly error message.

A set of **ErrorMessageParameters** can be used in combination with the manual **Message** or the corresponding message according to the **ErrorMessageKey** to format the final user-friendly error message to be returned.

The **FrontUserExceptionErrorMessageKey** enum is a list of common errors that can be automatically handled by the BIA Framework and configured to use a corresponding user-friendly error message.

### FrontUserException Inheritance
If needed, the **FrontUserException** can be inherited by a custom exception, adding a new enum identifier to improve exception identification throughout the application :

```csharp
public enum CustomErrorMessageKey
{
    BusinessError,
    TemplateBusinessError
}

public class CustomFrontUserException : FrontUserException
{
    public CustomFrontUserException(CustomErrorMessageKey errorMessageKey, Exception? innerException, params string[] errorMessageParameters)
        : base(GetErrorMessage(errorMessageKey), innerException, errorMessageParameters)
    {
        ErrorMessageKey = errorMessageKey;
    }

	// Mind the new instruction
    public new CustomErrorMessageKey ErrorMessageKey { get; }

	// Write your own method to get user friendly error message by key
    private static string GetErrorMessage(CustomErrorMessageKey errorMessageKey)
    {
        return errorMessageKey switch
        {
            CustomErrorMessageKey.BusinessError => "This is a business error",
            CustomErrorMessageKey.TemplateBusinessError => "This is a template business error - {0} - {1}",
        };
    }
}
```

### API Exception Handler with FrontUserException
When a **FrontUserException** is thrown and not handled, the [API Exception Handler](#configure-api-exception-handler) will automatically change the **HttpStatusCode** to **422** and return the error message to the end user inside the **HttpResponse.Body**.

The exception handler will automatically format the exception **Message** with the provided **ErrorMessageParameters**, if any, inside the **HttpResponse.Body**.

If the **Message** is null or empty (which is the case when using the **FrontUserException** constructor with only the **innerException** parameter), the **HttpResponse.Body** will contain the base exception message of the inner exception. For anonymization purposes, if the environment is not a development environment in that case, the **HttpResponse.Body** will only contain the message "**Internal server error**".

In a web application with a front end, the BIA Framework Angular will display an error pop-up with the error message.

### Throw a FrontUserException
The FrontUserException can be initialized with multiple constructors :

```csharp
// FrontUserException with only custom message
throw new FrontUserException("This is an error message", innerException: null);
// FrontUserException with only error message key
throw new FrontUserException(FrontUserExceptionErrorMessageKey.DatabaseDuplicateKey, innerException: null);
// FrontUserException with a custom templated message
throw new FrontUserException("This is an {0} {1}", innerException: null, "error", "message");

try
{
	// Do something
}
catch (Exception ex)
{
	// FrontUserException with only inner exception
	throw new FrontUserException(ex);
}
```

When using the constructor with only the **innerException** parameter, the error message of the **FrontUserException** will be an empty string.

### Catch a FrontUserException
The BIA Framework will throw some **FrontUserException**, allowing developers to catch them.

Most of these exceptions are raised from the Data layer and handled by the Domain layer inside the **FilteredServiceBase** class in a dedicated method **HandleFrontUserException**.

The purpose of this method is to analyze the content of the original **FrontUserException** coming from sub-layers and return a new one if needed.

This method can be overridden by all inherited objects from **FilteredServiceBase** to allow the developer to create custom behaviors:

```csharp
protected override Exception HandleFrontUserException(FrontUserException frontUserException)
{
	// Return a new FrontUserException with custom message, ignore previous exception
	return new FrontUserException("Custom message");
	
	// Do some actions based on the ErrorMessageKey
	if (frontUserException.ErrorMessageKey == FrontUserExceptionErrorMessageKey.DatabaseDuplicateKey)
	{
		// Do something...
	}
	// Return the FrontUserException handling by base service
	return base.HandleFrontUserException(frontUserException);
	
	// Return a new FrontUserException by specific ErrorMessageKey
	return frontUserException switch
	{
		FrontUserExceptionErrorMessageKey.DatabaseDuplicateKey => new FrontUserException("A similar {0} exists with the same value", frontUserException, nameof(MyEntity))
		_ => new FrontUserException("Application error, please contact support", frontUserException)
	};
	
	// Returning a null Exception will stop the catch instruction handling the original FrontUserException
	return null;
}
```

When some error information to fill in the error message template is not available in the error context, you can throw a new **FrontUserException** based on the original in the higher call context with the available information by redefining and completing the **errorMessageParameters** parameter.

Consider the example using the **CustomFrontUserException** defined in the [FrontUserException Inheritance](#frontuserexception-inheritance). The associated error message for **TemplateBusinessError** is "*This is a template business error - {0} - {1}*". The first template information is available in the **DeepLayer**, but the second one can only be retrieved in the higher call context **Layer** :

```csharp
public class DeepLayer
{
    private string DeepInformation => "Deep";

    public void Do()
    {
        try
        {
            // Do something
        }
        catch (Exception ex)
        {
			// Original CustomFrontUserException
            throw new CustomFrontUserException(CustomErrorMessageKey.TemplateBusinessError, ex, DeepInformation);
        }
    }
}

public class Layer
{
    private readonly DeepLayer deepLayer;
    private string LayerInformation => "Layer";

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
			// Catch the kind of CustomFrontUserException to complete
            if (ex.ErrorMessageKey == CustomErrorMessageKey.TemplateBusinessError)
            {
				// Throw new CustomFrontUserException using previous one data and complete with more error message parameters
                throw new CustomFrontUserException(ex.ErrorMessageKey, ex.InnerException, [.. ex.ErrorMessageParameters, this.LayerInformation]);
            }

            throw;
        }
    }
}
```
When the final **CustomFrontUserException** thrown is caught by the [API Exception Handler](#configure-api-exception-handler), the formatted message will be "*This is a template business error - Deep - Layer*".

**Note**: *When configuring templated error messages, ensure to provide the correct number of **errorMessageParameters** before the catch in the API exception handler to avoid format exceptions.*






