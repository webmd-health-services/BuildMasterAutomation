# BuildMasterAutomation Changelog

## 1.0.1

2021-8-3

* Publishing version 1.0.0 to GitHub failed. This version is identical to 1.0.0.

## 1.0.0

2021-8-3

* Updated to version 1.0.0 because there haven't been any breaking changes for over a year.
* Updated to support BuildMaster 6.1.28.
* Added support for PowerShell Core.

## 0.9.0

2020-2-12

* Improved import speed by merging all functions into the module's .psm1 file.
* Updating to support BuildMaster 6.1.25.
* Fixed: New-BMServerRole requires a request body in BuildMaster 6.1.25.

## 0.8.0

2019-10-31

* Added support for BuildMaster 6.1.17. Fixed an issue where environments created with `New-BMEnvironment` are disabled/inactive in that version.
* Added `Inactive` switch to `New-BMEnvironment` to create inactive/disabled environments. The default is to create active/enabled environments.

## 0.7.1

2019-7-8

* Fixed: Get-BMApplication, Get-BMApplicationGroup, and Get-BMPipeline fail if the user's WhatIfPreference is true.
* Fixed: New-BMEnvironment wasn't setting an environment's parent.
* Fixed: Get-BMEnvironment wasn't returning an environments parent.

## 0.7.0

2019-7-5

* Created `Get-BMServerRole`, `New-BMServerRole`, and `Remove-BMServerRole` functions for managing server roles.
* Created `Get-BMServer`, `New-BMServer`, and `Remove-BMServer` functions for managing servers.
* Created `Get-BMEnvironment`, `New-BMEnvironment`, `Disable-BMEnvironment`, and `Enable-BMEnvironment` functions for managing environments.
* Created `Get-BMVariable`, `Remove-BMVariable`, and `Set-BMVariable` functions for managing variables.

## 0.6.0

2018-11-29

* Created `Get-BMDeployment` function to retrieve deployment information for release packages.

## 0.5.0

2018-9-14

***This relese contains breaking changes. Please read the release notes carefully for upgrade instructions.***

* Created `Stop-BMRelease` function for canceling releases.
* Fixed: module functions don't respect calling scope preferences (e.g. VerbosePreference, ErrorActionPreference, etc.).
* Added `Force` switch to `Publish-BMReleasePackage` to force BuildMaster to deploy a package when it normally wouldn't.
* Changed the default HTTP method on `Invoke-BMRestMethod` and `Invoke-BMNativeApiMethod` from `POST` to `GET`. Update all your usages of these functions to add an explicit `-Method Post` parameter.
* Fixed: `Import-BuildMasterAutomation.ps1` script fails to remove exiting BuildMasterAutomation modules before re-importing when `WhatIfPreference` is `true`.
* Added `WhatIf` support to `Invoke-BMRestMethod` and `Invoke-BMNativeApiMethod`.
* Fixed: `Invoke-BMNativeApiMethod` fails when making HTTP GET requests.

## 0.0.0

* Created `New-BMSession` function for creating a session to a BuildMaster instance
* Created `Get-BMApplication` function for getting applications.
* Created `New-BMApplication` function for creating new applications.
* Created `Invoke-BMRestMethod` function for calling unimplemented API methods.
* Created `Invoke-BMNativeApiMethod` function for calling native API methods.
* Created `Add-BMObjectParameter` function to aid in converting and adding objects to parameter hashtables that get sent to BuildMaster in API requests.
* Created `New-BMRelease` function for creating releases.
* Created `Get-BMRelease` function for getting releases.
* Created `Get-BMPipeline` function for creating pipelines.
* Created `Get-BMReleasePackage` function for getting release packages.
* Created `New-BMReleasePackage` function for creating release packages.
* Created `Publish-BMReleasePackage` function for deploying a package.