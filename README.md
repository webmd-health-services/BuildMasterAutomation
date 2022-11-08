[![Build status](https://ci.appveyor.com/api/projects/status/github/webmd-health-services/buildmasterautomation?svg=true)](https://ci.appveyor.com/project/webmd-health-services/buildmasterautomation)

# Overview

BuildMaster Automation is a PowerShell module for automating [Inedo's BuildMaster](https://inedo.com/buildmaster), a
self-hosted tool for automating application builds, releases, and deployments.

This module wraps BuildMaster's [web APIs](https://inedo.com/support/documentation/buildmaster/reference/api) with
PowerShell functions

# System Requirements

* Windows PowerShell 5.1, PowerShell 6, and PowerShell 7
* BuildMaster 7.0 (some functions may work on older/newer versions)

# Installation

Install from the PowerShell Gallery:

     Install-Module BuildMasterAutomation

You can save the module to a prviate location with `Save-Module`:

    Save-Module BuildMasterAutomation -Path '.\PSModules'

You can download a ZIP file of the module from
[the project's GitHub Releases page](https://github.com/webmd-health-services/BuildMasterAutomation/releases).

# Getting Started

First, import the BuildMaster Automation module:

    Import-Module 'Path\To\BuildMasterAutomation'

If you put it in one of your `PSModulePath` directories, you can omit the path:

    Import-Module 'BuildMasterAutomation'

Next, create a connection object to the instance of BuildMaster you want to use along with the API key to use.

***NOTE: Authentication to BuildMaster is done using an API key that is sent to BuildMaster as an HTTP header, which is
visible to anyone listening on your network. Make sure your instance of BuildMaster is protected with SSL, otherwise
malicous users will be able to see your API key and will be able to access your instance of BuildMaster.***

    $session = New-BMSession -Url 'https://buildmaster.example.com' -ApiKey $apiKey

Now, you can create applications:

    New-BMApplication -Session $session -Name 'BuildMaster Automation'

You can create releases:

    New-BMRelease -Session $session -Application 'BuildMaster Automation' -Number '0.0' -Pipeline 'PowerShell Module'

To see a full list of available commands:

    Get-Command -Module 'BuildMasterAutomation'

If there isn't a PowerShell function a BuildMaster API endpoint, use the `Invoke-BMRestMethod` to call that API
endpoint.

    Invoke-BMRestMethod -Session $session -Name 'release'

Use `Invoke-BMNativeApiMethod` to call a native API endpoint:

    Invoke-BMNativeApiMethod -Session $session -Name 'Applications_GetApplications'

# Commands

## Create a Session to BuildMaster

* New-BMSession

## Functions That Call BuildMaster APIs

* Disable-BMApplication
* Get-BMApplication
* Get-BMApplicationGroup
* Get-BMBuild
* Get-BMDeployment
* Get-BMEnvironment
* Get-BMPipeline
* Get-BMRaft
* Get-BMRaftItem
* Get-BMRelease
* Get-BMServer
* Get-BMServerRole
* Get-BMVariable
* Invoke-BMNativeApiMethod
* Invoke-BMRestMethod
* New-BMApplication
* New-BMBuild
* New-BMEnvironment
* New-BMRelease
* New-BMServer
* New-BMServerRole
* Publish-BMReleaseBuild
* Remove-BMApplication
* Remove-BMEnvironment
* Remove-BMPipeline
* Remove-BMRaft
* Remove-BMRaftItem
* Remove-BMServer
* Remove-BMServerRole
* Remove-BMVariable
* Set-BMPipeline
* Set-BMRaft
* Set-BMRaftItem
* Set-BMRelease
* Set-BMVariable
* Stop-BMRelease

## Functions for Working with Objects Sent to/from BuildMaster

* Add-BMObjectParameter
* Add-BMParameter
* ConvertFrom-BMNativeApiByteValue
* ConvertTo-BMNativeApiByteValue
* Get-BMObjectName
* New-BMPipelinePostDeploymentOptionsObject
* New-BMPipelineStageObject
* New-BMPipelineStageTargetObject

# Contributing

Contributions are welcome and encouraged! First,
[create your own copy of this repository by "forking" it](https://help.github.com/articles/fork-a-repo/).

Next, [clone the repository to your local computer](https://help.github.com/articles/cloning-a-repository/).

Finally, before you can write tests and code, you'll need to install the module's pre-requisites. Run:

    > .\init.ps1

This script will install modules needed to develop and run tests. It will also download and install a copy of
BuildMaster including an instance of SQL Server 2005 Express named `BuildMaster`. All tests connect to this local
instance of BuildMaster.

We use [Pester 5](https://pester.dev) as our testing framework. A copy of Pester is saved to the repository
root directory by `init.ps1`. To run tests, import Pester, and use `Invoke-Pester`:

    > Import-Module '.\Pester'
    > Invoke-Pester '.\Tests'

Test scripts go in the `Tests` directory. New functions go in the `BuildMasterAutomation\Functions` directory.