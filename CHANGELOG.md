# BuildMasterAutomation Changelog

## 2.0.0

### Upgrade Instructions

***This release contains breaking changes. Please read these upgrade instructions carefully before upgrading.***

This release adds support for BuildMaster 6.2.33, which contains breaking changes from version 6.1.

* Remove usages of the `Get-BMDeployment` function's `Build`, `Release`, and `Application` parameters. The BuildMaster [Release and build deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build) no longer
supports getting deploys for builds, releases, and applications.
* Rename usages of the `Get-BMDeployment` function's `ID` parameter to `Deployment`.
* Remove usages of the `New-BMApplication` function's `AllowMultipleActiveBuilds` switch. This functionality was
removed from BuildMaster.
* Rename usages of `New-BMPipeline` to `Set-BMPipeline`.
* Update values passed to the `Set-BMPipeline` (née `New-BMPipeline`) function's `Stage` parameter. This parameter now
requires an array of stage objects, which can be created with the new `New-BMPipelineStageObject` function.
* Remove usages of the `Get-BMPipeline` function's `ID` parameter. BuildMaster pipelines no longer have ids, just
names.
* Update usages of the `Get-BMPipeline` function to pass a pipeline name to the `Name` parameter instead of an id.
* Objects returned by `Get-BMPipeline` are now raft item objects. Check usages to ensure you're using correct
properties.
* Rename usages of the `New-BMPipeline` function to `Set-BMPipeline`.
* `Set-BMPipeline` (née `New-BMPipeline`) now creates *or* updates a pipeline. Inspect usages to see the impact of this
new behavior.
* Update usages of the `Set-BMPipeline` (née `New-BMPipeline`) function's `Stage` parameter to pass stage objects
instead of strings of XML. Use the new `New-BMPipelineStageObject` and `New-BMPipelineStageTargetObject` functions to
create the objects you should pass.
* Update usages of the `Set-BMPipeline` (née `New-BMPipeline`) function that use the return value. `Set-BMPipeline` no
longer returns the pipeline object by default. Use the new `PassThru` switch and the pipeline object will be returned.
* Add `-ErrorAction Ignore` to usages of `Remove-BMServer` and `Remove-BMServerRole` if you don't care if the item doesn't exist. `Remove-BMServer` and `Remove-BMServerRole` now write errors when the item to remove doesn't exist.
* Update usages of `Set-BMRelease` to pass a pipeline name or pipeline object to the new `Pipeline` paramter and remove
usages of the `PipelineID` parameter.

### Added

* Function `Add-BMParameter`, for adding values to a parameter hashtable (i.e. a hashtable that will be used as the body
of a request to a BuildMaster API endpoint). If the value is `$null`, however, it won't be added.
* Function `ConvertFrom-BMNativeApiByteValue` for converting `byte[]` values returned by the BuildMaster native API
into their original strings.
* Function `Get-BMObjectName` for getting the name of an object that was returned by the BuildMaster API.
* Function `Get-BMBuild` for getting builds. It replaces the now obsolete `Get-BMPackage` function.
* Parameter `Application` to the `Get-BMPipeline` function. It replaces the now obsolete parameter `ApplicationID`.
* Function `Get-BMRaft` for getting all rafts.
* Function `Get-BMRaftItem` for getting all raft items.
* Parameter `Application` on the `New-BMApplication` function. It replaces the now obsolete parameter
`ApplicationGroupID`.
* Function `New-BMBuild` for creating builds. It replaces the now obsolete `New-BMPackage` function.
* Function `New-BMPipelinePostDeploymentOptionsObject` for creating a post-deployment options object to use when
creating a pipeline.
* Function `New-BMPipelineStageObject` for creating a stage object that can be passed to the `Set-BMPipeline` function's
`Stage` parameter.
* Function `New-BMPipelineStageTargetObject` for creating a target object that can be passed to the
`New-BMPipelineStageObject` function's `Target` parameter.
* Parameter `Url` to the `New-BMSession` function. It replaces the now obsolete parameter `Uri` parameter.
* Function `Publish-BMReleaseBuild`. It replaces the now obsolete `Publish-BMReleasePackage` function.
* Function `Remove-BMApplication` function for deleting applications.
* Function `Remove-BMPipeline` function for removing pipelines.
* Function `Remove-BMRaftItem` function for deleting raft items.
* Parameter `PostDeploymentOption` to the `Set-BMPipeline` (née `New-BMPipeline`) function for configuring a pipeline's
post-deployment options. Use the `New-BMPipelinePostDeploymentOptionsObject` to create a post-deployment options object.
* Parameter `EnforceStageSequence` to the `Set-BMPipeline` (née `New-BMPipeline`) function for controlling the
pipeline's stage sequence enforcement.
* Function `Set-BMRaftItem` for creating and/or updating a raft item.
* Parameter `PassThru` to the `Set-BMPipeline` (née `New-BMPipeline`) for returning the created/updated pipeline object.
* Parameter `Pipeline` to the `Set-BMRelease` function. This replaces the `PipelineID` parameter, which was removed.

### Changed

* The `Add-BMObjectParameter` function now accepts `$null` values. When passed a null value, it does nothing.
* Renamed the `New-BMPipeline` function to `Set-BMPipeline` since the underlying API no longer has separate create and
update endpoints, but a single create or update endpoint.
* Renamed `Get-BMDeployment` function's `ID` parameter to `Deployment` and updated it to also accept deployment
objects.
* `Get-BMPipeline` function returns raft item objects instead of pipeline objects.
* Renamed the `New-BMPackage` function's `PackageNumber` parameter to `BuildNumber`.
* Renamed the `New-BMPipeline` function to `Set-BMPipeline` and updated it to create and/or update the pipeline.
* The `Set-BMPipeline` (née `New-BMPipeline`) function's `Stage` parameter to take in stage objects instead of XML
strings. Use the new `New-BMPipelineStageObject` and `New-BMPipelineStageTargetObject` functions to create the objects
you should pass.
* `Set-BMPipeline` (née `New-BMPipeline`) no longer returns the pipeline. Use the `PassThru` switch to have the pipeline
object returned.
* `Remove-BMServer` and `Remove-BMServerRole` now write an error when the item to delete doesn't exist. Use
`-ErrorAction Ignore` to ignore if the item exists or not.

### Deprecated

#### Functions

* The `Get-BMPackage` function. It is replaced by `Get-BMBuild`.
* The `New-BMPackage` function. It is replaced by `New-BMBuild`.
* The `Publish-BMReleasePackage` function. It is replaced by `Publish-BMReleaseBuild`.

#### Function Parameters

* The `Get-BMPipeline` function's `ApplicationID` parameter. Use the new `Application` parameter instead.
* The `New-BMApplication` function's `ApplicationGroupID` parameter. Use the new `ApplicationGroup` parameter instead.
* The `New-BMSession` function's `Uri` parameter. Use the new `Url` parameter instead.

#### Object Properties

* The `Uri` property on session objects. Use the new `Url` property instead.
* The `Pipeline_Name` property on pipeline objects. Use the new `RaftItem_Name` property instead.
* The `Pipeline_Id` property on pipeline objects. Use the new `RaftItem_Id` property instead.

### Fixed

* `Invoke-BMRestMethod` (and by extension all the BuildMasterAutomation functions that call the API) no longer returns
`$null`.
* `Invoke-BMRestMethod` fails to log request body to the debug stream when using the `Body` parameter.

### Removed

* `New-BMApplication` function's `AllowMultipleActiveBuilds` switch. Its functionality was removed from BuildMaster.
* `Get-BMPipeline` function's `ID` parameter. Use the `Name` parameter instead. BuildMaster pipelines no longer have
ids, just names.
* Removed the `Get-BMDeployment` function's `Build`, `Release`, and `Application` parameters. The BuildMaster
[Release and Build Deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build) no longer
supports getting deploys for builds, releases, and applications.
* Parameter `PipelineID` on the `Get-BMRelease` function. Use the new `Pipeline` parameter instead.

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