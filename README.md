# PIVPosh
PIVPosh is a Powershell integration of the Pivotal (Download) API
it allows you to Dynamically retrieve content from Pivotal Network

![piv posh overview](https://user-images.githubusercontent.com/8255007/42770899-c4aacc26-8925-11e8-8566-ff6dfd50d50c.gif)  
## Getting started
PIVPosh is available from the Powershell Gallery.  
Install the Module with Install-Module command.  
### install PIVPosh
```Powershell
Install-Module PIVPosh -Scope CurrentUser -Force
```
### load the Module

```Powershell
ipmo .\PIVPosh
```
### list Commands
```Powershell
Get-Command -Module PIVPosh
```
![image](https://user-images.githubusercontent.com/8255007/42768798-be51bfb0-8920-11e8-9286-ce97e0a03544.png)


## first basic commands
### Get all available Products on Pivotal Network 
```Powershell
Get-PIVSlug
```
![image](https://user-images.githubusercontent.com/8255007/42769117-9845d6e8-8921-11e8-9e43-639a971b7f6b.png)

### Retrieving Product Information for a Specific Product by name
this is a dynamic commandlet, i.e. it will online parse valid values for the Name Parameter
```Powershell
Get-PIVSlug -Name 'Pivotal Container Service (PKS)'
```
![picslug](https://user-images.githubusercontent.com/8255007/42769723-562dd72c-8923-11e8-91c6-38baad87af10.gif)


## example
get all releses for a specific version of a product
```Powershell
Get-PIVSlug -Name 'Pivotal Cloud Foundry Operations Manager' | Get-PIVRelease | where version -ge 2.2
```


## example
retrive specific files without EULA requirement
```Powershell
 Get-PIVSlug -Name 'Pivotal Cloud Foundry Operations Manager' | Get-PIVRelease | where version -ge 2.2 | Get-PIVFileReleaseId | where name -match azure | Get-PIVFilebyReleaseObject -access_token $token
```

