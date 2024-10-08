---
sidebar_position: 1
---

# Unit tests for V3 projects
This file explains what to do in order to add unit tests for the back-end of your V3 project.

It contains an overview of the architecture, but if you just want to know how to create your own unit tests project, go directly to chapter **How to add unit tests for my project?**.

---

## Prerequisite

### Knowledge to have:
* [Unit test best practices and naming conventions](https://docs.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices)
* [MStest](https://docs.microsoft.com/en-us/dotnet/core/testing/unit-testing-with-mstest)
* We cannot mock static methods with the default test framework (so, the same thing applies to extension methods).

###  Test attributes
As explained [here](https://docs.microsoft.com/en-us/previous-versions/visualstudio/visual-studio-2012/ms245572(v=vs.110)#examples) or in **UnitTestExample** (one of the files provided in the example project), there are some attributes that can/have to be used for unit tests:
* Every test suite shall be a class with the `[TestClass]` attribute. 
A test suite is class containing several tests related to the same topic.
* Every test shall be a method with the `[TestMethod]` attribute inside a test suite.
* If you want to test the same thing but with different inputs, you can use a `[DataTestMethod]` attribute instead of the `TestMethod` one.
This attribute can be used in combination with several `[DataRow(x, y, z)]` attributes. Each `DataRow` will be an execution of the test with the given inputs (x, y, z).
Note: you can add as many input parameters as you want.
Example:
  ``` csharp
    [DataTestMethod]
    [DataRow(-1, true)]
    [DataRow(0, true)]
    [DataRow(1, true)]
    [DataRow(2, false)]**
    public void TestMethodFactorized(int value, bool expectedResult)
    {
        Assert.AreEqual(expectedResult, value < 2);
    }
  ```
* The `[ClassInitialize]` attribute can be used on a method that will be executed **once** for the whole test suite, **before the first test**. 
It can be used to setup a global context for the whole test suite.
* The `[ClassCleanup]` attribute can be used on a method that will be executed **once** for the whole test suite, **after the last test**.
It can be used to reset any configuration that was setup previously.
* The `[TestInitialize]` attribute can be used on a method that will be executed **before each test**. (in our case, we use it to reset the DB mock and IoC)
*  The `[TestCleanup]` attribute can be used on a method that will be executed **after each test**.

---

## Overview
Here is an overview of the architecture.
### BIA.Net.Core.Test
**BIA.Net.Core.Test** project contains some basic classes that:
* Hide some of the complexity of the tests
* Manage part of the IoC
* Allow to mock some user related data (user ID, user rights, etc)

It only uses common data (that are **not** strongly related to your project).

**PrincipalMockBuilder** helps you create a mock where you can easily customize user related information (user id, user rights, etc).
It follows the Builder pattern, so you can chain several method calls to configure your mock. The mocked object is automatically applied to the IoC before each test.

**BIAAbstractUnitTest** is the base class of all unit tests.
It contains mechanisms used to:
* Access the database mock (through the `DbMock` property)
* Manage the IoC services (through the `servicesCollection` attribute) and retrieve more easily instances of injected services and controllers (through the `GetService\<T>` and `GetControllerWithHttpContext\<TController>` methods)
* Manage the user mock (through the `principalBuilder` attribute)
* Eventually add default data at the beginning of each test (through the `isInitDB` attribute)

### Unit test project
Your unit test project shall:
* Contain all your tests
* Define more precisely how we interact with the database mock
* Define the IoC part that is strongly coupled to your project (services, controllers and DbContext)

By default, we are using an **'in memory'** Entity Framework database to mock the database context (through the use of `MockEntityFrameworkInMemory`).
It means that you can manipulate directly `DbSet` objects, but nothing will be stored on your file system (just kept in RAM).

Each test shall extend `AbstractUnitTest`.

IoC of classes strongly coupled to your project shall be defined in `IocContainerTest`.

---

## How to add unit tests for my project?
If you want to know what to do in order to add unit tests to your project, this is the way...

#### Customize database mock and IoC
No the real work starts! :)
We will configure how to interact with the 'in memory' database and how to perform IoC.

* Modify **MockEntityFrameWorkInMemory**. 
This is the class mocking the database context to an 'in memory' Entity Framework database.
  * It shall extend `AbstractMockEntityFramework\<T>` where T is your `DbContext`.
  If you are using the default name for your `DbContext`, it shall be `DataContext` and you have nothing to change.
  * Normally, you should already have gotten rid of any reference to `Plane`, but if this is not the case, now is the time to do so.
  * If you want to manipulate other tables, you can add methods to do so here. 
  The `GetDbContext()` method gives you access to all available tables, so you can use it to implement those new methods.
  * The `InitDefaultData()` method can be used to add some data before each test that is configured to do so. 
  So, feel free to modify it, **but be careful: it can have an impact on every test that has been created with `isInitDB = true`**.

* Modify **IocContainerTest**. 
This is the class configuring the IoC for our unit tests.
  * If you followed the previous steps, you already modified `IocContainer.ConfigureContainer()` in order to add a third parameter and change its implementation.
  * Modify `IocContainerTest.ConfigureControllerContainer()`. You should add a dependency injection for every controller you want to test. This is usually quite a dummy one: `services.AddTransient<MyController, MyController>();`
  
_Normally, everything should be set up right now._

If this is not the case, well here are some leads:
* Your `DbContext` is not named `DataContext`. Then you have to replace `DataContext` by the correct name everywhere.


#### Create your own tests
Now that we configured everything correctly, it's time to write some tests!
You can take examples on the existing ones, but here are some guidelines.

##### Architecture
* Your test suites shall be created in the "**Tests**" folder.
The default structure is the following one:
> [YourCompanyName].[YourProjectName].Test
> &nbsp;&nbsp;|\_ Tests
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|\_ Controllers
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|\_ One class for each controller you want to test
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|\_ Services
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|\_ One class for each service you want to test
* Create a test suite for every topic (for example, sites, users, planes, etc).
But you can even be more specific. 
For example, you can create several test suites related to the same global topic (for example, sites), but each test suite having a specific context (for example, some specific user rights). 
This can allow you to centralize some initialization in the `[TestInitialize]` method rather than doing it in every test.

##### Test suites
* Each test suite shall be a class:
  * With the `[TestClass]` attribute.
  * Extending `AbstractUnitTest`.
  * With a default constructor (without parameter) calling the base constructor with a boolean parameter:
  ``` csharp
   public MyControllerTests() 
   : base(false) 
   {

   }
   ```
  This boolean parameter is used to define if we shall call the `MockEntityFrameworkInMemory.InitDefaultData()` before each test or not (in order to add some default data in the DB). It is up to you to decide if you want to use <code>true</code> or <code>false</code>.
  * **[Optional]** With a method with the `[TestInitialize]` attribute.
  In this method, you can setup a context that is common to every test.
  For example, you can instantiate the controller/service you want to test, add some data in the DB, mock some user related data, etc.

##### Tests
* To easily create a test for each method of a service/controller, you can do the following in Visual Studio:
  * In your test project, create the file where you want to put your tests.
  * Copy its namespace (it will save you some time later).
  * Open the service/controller you want to create tests for.
  * Right-click inside the class and select "**Create Unit Tests**".
  * Change only the following options:
    * **Test Project**: select your existing test project.
    * **Namespace**: paste the namespace you copied earlier.
    * **Output file**: select the test file you created.
  * Click OK. Visual Studio will create a test method for each method of your service/controller, even the constructor!
  * Remove the constructor test.
  * **[Optional]** Remove the "**()**" in each `[TestMethod()]` attribute or fill it with the desired display name.
* Each test shall be a method with the `[TestMethod]` or `[DataTestMethod]` attribute.
You can add an optional parameter to this attribute in order to configure the name which will be displayed in the test report. It can be a good idea to do so, because by default it only uses the method name (so if you have several methods with the same name in different test suites, you won't directly differentiate them).
* Refer to [Unit test best practices and naming conventions](https://docs.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices) in order to name your tests correctly.
* Try to keep your tests small and with one single objective.
* For **controller tests**, you can:
  * Retrieve the **HTTP status code** of an API by casting its returned value into an `IStatusCodeActionResult`.
  For example:
    ``` csharp
    this.controller = this.GetControllerWithHttpContext<SitesController>();
    IStatusCodeActionResult response = this.controller.Add(siteDto).Result as IStatusCodeActionResult;
    Assert.IsNotNull(response);
    Assert.AreEqual((int)HttpStatusCode.Created, response.StatusCode);
    ```
  * Retrieve the **HTTP status code and the returned value** of an API by casting its returned value into an `ObjectResult`.
  For example:
    ``` csharp
    this.controller = this.GetControllerWithHttpContext<SitesController>();
    ObjectResult response = this.controller.GetAll(filter).Result as ObjectResult;
    Assert.IsNotNull(response);
    Assert.AreEqual((int)HttpStatusCode.OK, response.StatusCode);
    IEnumerable<SiteInfoDto> listSites = response.Value as IEnumerable<SiteInfoDto>;
    Assert.IsNotNull(listSites);
    Assert.AreEqual(1, listSites.Count());
    ```
* For **service tests**, you can:
  * Check the returned DTO.
  * Check the DB has been correctly updated by using `this.DbMock`:
    * Either by calling the helper methods you created in `MockEntityFrameworkInMemory`
    * Or by using `this.DbMock.GetDbContext()` which gives you a direct access to the `DbSet` objects.

##### IoC and mock
* Use `GetService\<T>` and `GetControllerWithHttpContext\<TController>` methods from `BIAAbstractUnitTest` to instantiate your services and controllers through IoC.
For the controllers, it will automatically configure an HttpContext that is required by most of the APIs we implemented in V3 projects.
* Use `this.DbMock` in order to access to the database and:
  * Check if the correct data is stored in DB,
  * Add/Remove data from the DB to **setup your test context**.
* Use `this.principalBuilder` to mock some user related information (user ID, user rights, etc).
You only have to call the `MockXxxx()` methods in order to setup the information you want to mock. The mocked object is automatically generated and applied when initializing the test.
* Since most of our APIs are asynchronous, use `Result` to wait for the call to be complete and retrieve the returned value.
For example: 
  ``` csharp
  ISiteAppService service = this.GetService<ISiteAppService>();  
  SiteDto site = service.GetAsync(1).Result;
  ```
