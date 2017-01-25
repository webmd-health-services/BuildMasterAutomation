[![Build status](https://ci.appveyor.com/api/projects/status/github/pshdo/buildmasterautomation?svg=true)](https://ci.appveyor.com/project/splatteredbits/buildmasterautomation)

# Overview

BuildMaster Automation is a PowerShell module for automation [Inedo's BuildMaster](https://inedo.com/buildmaster). BuildMaster is a self-hosted tool for automating application deployment.

With this module, you can:

 * Create and get applications
 * Create and get releases
 * Call BuildMaster's [native or other REST APIs](https://inedo.com/support/documentation/buildmaster/reference/api).
 
# Installation
 
To download, go to this project's [Github source code repository](https://github.com/pshdo/BuildMasterAutomation), click the green "Clone or Download" button, and choose "Download ZIP." Once the ZIP file is downloaded, right-click it and choose "Properties". On the Properties dialog box, click the "Unblock" button.
 
To install, open the downloaded ZIP file. The module is in the BuildMasterAutomation directory. Put that directory anywhere you want. 
 
# Getting Started

First, import the BuildMaster Automation module:

    Import-Module 'Path\To\BuildMasterAutomation'
    
If you put it in one of your `PSModulePath` directories, you can omit the path:

    Import-Module 'BuildMasterAutomation'
 
Next, create a connection object to the instance of BuildMaster you want to use along with the API key to use.
 
***NOTE: Authentication to BuildMaster is done using an API key that is sent to BuildMaster as an HTTP header, which is visible to anyone listening on your network. Make sure your instance of BuildMaster is protected with SSL, otherwise malicous users will be able to see your API key and will be able to access your instance of BuildMaster.***

    $session = New-BMSession -Uri 'https://buildmaster.example.com' -ApiKey $apiKey
    
Now, you can create applications:

    New-BMApplication -Session $session -Name 'BuildMaster Automation'
    
You can create releases:

    New-BMRelease -Session $session -Application 'BuildMaster Automation' -Number '0.0' -Pipeline 'PowerShell Module'
    
To see a full list of available commands:

    Get-Command -Module 'BuildMasterAutomation'
    
You can always call an API using `Invoke-BMRestMethod`:

    Invoke-BMRestMethod -Session $session -Name 'release'
    
You can also call a native BuildMaster API with `Invoke-BMNativeApiMethod`:

    Invoke-BMNativeApiMethod -Session $session -Name 'Pipelines_GetPipelines'
    

# Contributing

Contributions are welcome and encouraged! First, [create your own copy of this repository by "forking" it](https://help.github.com/articles/fork-a-repo/). 

Next, [clone the repository to your local computer](https://help.github.com/articles/cloning-a-repository/).

Finally, before you can write tests and code, you'll need to install the module's pre-requisites. Run:

    > .\init.ps1
    
This script will install modules needed to develop and run tests. It will also download and install a copy of BuildMaster including an instance of SQL Server 2005 Express named `BuildMaster`. All tests connect to this local instance of BuildMaster. 

We use [Pester](https://github.com/pester/Pester) as our testing framework. A copy of Pester is saved to the repository root directory by `init.ps1`. To run tests, import Pester, and use `Invoke-Pester`:

    > Import-Module '.\Pester'
    > Invoke-Pester '.\Tests'
    
Test scripts go in the `Tests` directory. New functions go in the `BuildMasterAutomation\Functions` directory. 

