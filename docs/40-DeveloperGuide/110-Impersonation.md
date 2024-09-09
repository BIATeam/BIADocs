---
sidebar_position: 1
---

# Impersonation

This file explains how to use the impersonation helper class.

## Usage

For access rights reasons, it is sometimes necessary to use another account than the current service account to call an external resource.
This is called impersonation.
To do this, we will use the class : **BIA.Net.Core.Common.Helpers.WindowsIdentityHelper**
Here is an example of impersonation. We are going to use another account to retrieve a file from a folder.

``` csharp
        public Task<FileStream> GetFileAsync(string path)
        {
                // Here we have the code we want to run with another account : File.OpenRead(path)
                // We create a method pointer, Func, so that we can pass it to our impersonation method
                Func<Task<FileStream>> func =
                    () =>
                    {
                        return Task.Run(() => File.OpenRead(path));
                    };

                // This is just one example. You will have to store the credentials in an encrypted place, like the Windows vault
                string domain = "MyDomain";
                string account = "MyAccount";
                string password = "MyPassword";

                // Here we execute the code File.OpenRead(path) with specific credentials
                return WindowsIdentityHelper.RunImpersonated(domain, account, password, func);
        }
```
