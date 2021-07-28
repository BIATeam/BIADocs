# BIA Framework

## Configure your environment Git

### Company Customisation
If your company have a proxy specify it (exact values can be describe in your company docs : CompanyConfig.md) else follow those steps.

### Configuration for the Company proxy
[Add the following **User** environment variables :](https://www.tenforums.com/tutorials/121664-set-new-user-system-environment-variables-windows.html#option1)  
* HTTP_PROXY: [Add here your proxy]
* HTTPS_PROXY: [Add here your proxy]
* NO_PROXY: [Add here the local domain extensions taht do not need proxy separate by a space]

### Git config
To find the path to the **.gitconfig** file, type the following command:   
`git config --list --show-origin`   
Open your **.gitconfig** file and add this configuration:
```
[http]
	sslVerify = false
	proxy = "[Add here your proxy if requiered]"
```
