<!-- markdownlint-disable MD024 no-duplicate-heading/no-duplicate-header -->
# BuildMasterAutomation Changelog

## 3.0.0

Minimum supported version of BuildMaster is now 7.0.

### Upgrade Instructions

***This release contains breaking changes. Please read these upgrade instructions carefully before upgrading.***

BuildMaster no longer supports active/inactive environments.

* Remove usages of the `Disable-BMEnvironment` and `Enable-BMEnvironment` functions.
* Remove usages of the `Get-BMEnvironment` and `Remove-Environment` functions' `Force` switch, which was used to
operate on inactive environments.

These functions were updated to use BuildMaster's
[Infrastructure Management API](https://docs.inedo.com/docs/buildmaster-reference-api-infrastructure). For each, check
API key usages to ensure the key has access to that API and check that property usages on any return objects are using
[the correct names](https://docs.inedo.com/docs/buildmaster-reference-api-infrastructure).

* `Get-BMEnvironment`
* `Remove-BMEnvironment`

BuildMaster no longer supports active/inactive applications.

* Remove usages of the `Active_Indicator` property on application objects.

### Changed

* The `Get-BMEnvironment` function now uses the BuildMaster
[Infrastructure Management API](https://docs.inedo.com/docs/buildmaster-reference-api-infrastructure). Property names on
return object may be different. Different API key permissions are required.
* The `Remove-BMEnvironment` function now uses the BuildMaster
[Infrastructure Management API](https://docs.inedo.com/docs/buildmaster-reference-api-infrastructure). Different API key
permissions are required.

### Removed

#### Functions

* `Disable-BMEnvironment`
* `Enable-BMEnvironment`

#### Parameters

* `Force` switch from `Get-BMEnvironment` and `Remove-BMEnvironment`.

## 2.0.0

2022-11-7

### Supported Versions

This version of BuildMasterAutomation is only supported on BuildMaster 6.2. Some of it may work on older or newer
versions, but we've only tested against BuildMaster 6.2.33.

### Known Issues

The `Get-BMVariable` function fails to get variables from applications or application groups, due to a bug in the
BuildMaster [Variables Mangement API](https://docs.inedo.com/docs/buildmaster-reference-api-variables).

### Upgrade Instructions

***This release contains breaking changes. Please read these upgrade instructions carefully before upgrading.***

This release adds support for BuildMaster 6.2.33, which contains breaking changes from version 6.1.

* These functions now write an error if an item doesn't exist (for `Get`, `Remove`, and `Set` functions) or if an item
already exists (for `New` functions). Add `-ErrorAction Ignore` to existing usages to preserve previous behavior:
  * `Disable-BMEnvironment`
  * `Enable-BMEnvironment`
  * `Get-BMApplication`
  * `Get-BMApplicationGroup`
  * `Get-BMDeployment`
  * `Get-BMEnvironment`
  * `Get-BMRelease`
  * `Get-BMServer`
  * `Get-BMServerRole`
  * `New-BMApplication`
  * `Remove-BMServer`
  * `Remove-BMServerRole`
  * `Remove-BMVariable`
  * `Set-BMRelease`
* Remove usages of the `Get-BMDeployment` function's `Build`, `Release`, and `Application` parameters. The BuildMaster
[Release and build deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build) no longer
supports getting deploys for builds, releases, and applications.
* Remove usages of the `Get-BMPipeline` function's `ID` parameter. BuildMaster pipelines no longer have ids, just
names.
* Update usages of the `Get-BMPipeline` function to pass a pipeline name to the `Name` parameter instead of an id.
* Objects returned by `Get-BMPipeline` are now raft item objects. Check usages to ensure you're using correct
properties.
* Remove usages of the `New-BMApplication` function's `AllowMultipleActiveBuilds` switch. This functionality was
removed from BuildMaster.
* Rename usages of `New-BMPipeline` to `Set-BMPipeline`.
* `Set-BMPipeline` (née `New-BMPipeline`) now creates *or* updates a pipeline. Inspect usages to see the impact of this
new behavior.
* Update usages of the `Set-BMPipeline` (née `New-BMPipeline`) function's `Stage` parameter to pass stage objects
instead of strings of XML. Use the new `New-BMPipelineStageObject` and `New-BMPipelineStageTargetObject` functions to
create the objects you should pass.
* Update usages of the `Set-BMPipeline` (née `New-BMPipeline`) function: its new `Raft` parameter is required. To use
BuildMaster's default raft, pass `1` as the value.
* Add `-PassThru` to usages of the `Set-BMPipeline` (née `New-BMPipeline`) function that expect a return value.
The `Set-BMPipeline` (née `New-BMPipeline`) function no longer returns the pipeline object by default.
* Update usages of `Set-BMRelease` to pass a pipeline name or pipeline object to the new `Pipeline` paramter and remove
usages of the `PipelineID` parameter.

### Added

#### Functions

* `Add-BMParameter`, for adding values to a parameter hashtable (i.e. a hashtable that will be used as the body of a
request to a BuildMaster API endpoint). If the value is `$null`, however, it won't be added.
* `ConvertFrom-BMNativeApiByteValue` for converting `byte[]` values returned by the BuildMaster native API into their
original strings.
* `Get-BMBuild` for getting builds. It replaces the now obsolete `Get-BMPackage` function.
* `Get-BMObjectName` for getting the name of an object that was returned by the BuildMaster API.
* `Get-BMRaft` for getting rafts.
* `Get-BMRaftItem` for getting raft items.
* `New-BMBuild` for creating builds. It replaces the now obsolete `New-BMPackage` function.
* `New-BMPipelinePostDeploymentOptionsObject` for creating a post-deployment options object to use when creating a
pipeline.
* `New-BMPipelineStageObject` for creating a stage object that can be passed to the `Set-BMPipeline` function's `Stage`
parameter.
* `New-BMPipelineStageTargetObject` for creating a target object that can be passed to the `New-BMPipelineStageObject`
function's `Target` parameter.
* `Publish-BMReleaseBuild`. It replaces the now obsolete `Publish-BMReleasePackage` function.
* `Remove-BMApplication` function for deleting applications.
* `Remove-BMEnvironment` for deleting an environment.
* `Remove-BMPipeline` function for removing pipelines.
* `Remove-BMRaft` for removing a raft.
* `Remove-BMRaftItem` function for deleting raft items.
* `Set-BMRaft` for creating and updating rafts.
* `Set-BMRaftItem` for creating and/or updating a raft item.

#### Parameters

* `Add-BMObjectParameter`:
  * `AsID` to only set a parameter from an object's id, ignoring any names.
  * `AsName` to only set a parameter from an object's name, ignoring any ids.
* `Get-BMApplication`:
  * `Application`: accepts an application id, name, or application object. Wildcards supported when passing a name.
  * `ApplicationGroup`: accepts an application group id, name, or application group object. Wildcards supported when
  passing a name.
* `Get-BMDeployment`: `Deployment`, which accepts a deployment id or deployment object.
* `Get-BMEnvironment`: `Environment`, which accepts environment ids, names, or environment objects. Wildcards supported
when passing a name.
* `Get-BMPipeline`:
  * `Application`:, for setting the application for the pipeline; accepts an application id, name, or application
  object. Wildcards supported when passing a name.
  * `Raft` parameter to the `Get-BMPipeline` function for only getting pipelines in a specific raft.
* `Get-BMServer`: `Server`, which accepts server ids, names, or server objects. Wildcards supported when passing a name.
* `Get-BMServerRole`: `ServerRole`, which accepts server ids, names, or server objects. Wildcards supported when passing
a name.
* `Get-BMVariable` and `Remove-BMVariable` (wildcards supported when passing a name to any of these parameters):
  * `Application`: accepts application ids, names, or application objects.
  * `ApplicationGroup`: accepts application group ids, names, or application group objects.
  * `Environment`: accepts environment ids, names, or environment objects.
  * `Server`: accepts server ids, names, or server objects.
  * `ServerRole`: accepts server role ids, names, or server names.
* `New-BMApplication`:
  * `ApplicationGroup`: for assigning the application group to a new application; accepts application group ids, names,
  or application group objects. Wildcards supported when passing a name.
  * `Raft`: for setting the raft in which the application's scripts, pipelines, etc. will be saved.
* `New-Environment`: `PassThru`, for returning the environment.
* `New-BMSession`: `Url`, which is the URL to BuildMaster; `Url` replaces the now obsolete `Uri` parameter.
* `Remove-BMServer`: `Server`, which accepts server ids, names, or server objects. Wildcards supported when passed a
name.
* `Remove-BMServerRole`: `ServerRole`, which accepts server role ids, names, or server objects. Wildcards supported when
passed a name.
* `Set-BMPipeline` (née `New-BMPipeline`):
  * `PostDeploymentOption`: configures a pipeline's post-deployment options. Use the
  `New-BMPipelinePostDeploymentOptionsObject` to create a post-deployment options object.
  * `EnforceStageSequence`: controls the pipeline's stage sequence enforcement.
  * `PassThru`: when set, returns the created/updated pipeline object.
* `Set-BMRelease`: `Pipeline`, to set the pipeline for the release; this replaces the obsolete `PipelineID` parameter.

### Changed

* These functions now write an error if an item doesn't exist (for `Get` and `Remove` functions) or if an item already
exists (for `New` functions). Add `-ErrorAction Ignore` to existing usages to preserve previous behavior:
  * `Disable-BMEnvironment`
  * `Enable-BMEnvironment`
  * `Get-BMApplication`
  * `Get-BMApplicationGroup`
  * `Get-BMDeployment`
  * `Get-BMEnvironment`
  * `Get-BMRelease`
  * `Get-BMServer`
  * `Get-BMServerRole`
  * `New-BMApplication`
  * `Remove-BMServer`
  * `Remove-BMServerRole`
  * `Remove-BMVariable`
  * `Set-BMRelease`
* `Add-BMObjectParameter` now accepts `$null` values. When passed a null value, it does nothing.
* `Disable-BMEnvironment`: the `Environment` parameter now accepts an environment id, name, and environment object for a
value.
* `Enable-BMEnvironment`: the `Environment` parameter now accepts an environment id, name, and environment object for a
value.
* `Get-BMApplicationGroup` now accepts application group ids, names, or application group objects as pipeline input.
* `Get-BMEnvironment` now accepts environment ids, names, or environment objects as pipeline input.
* `Get-BMPipeline` returns raft item objects instead of pipeline objects.
* `Get-BMServer` now accepts server names, ids, and server objects as pipeline input.
* `Get-BMServerRole` now accepts server role names, ids, and server objects as pipeline input.
* `Get-BMApplication` now accepts application ids, names, or application objects as pipeline input.
* `New-BMPipeline` renamed to `Set-BMPipeline` and:
  * it creates and/or updates a pipeline.
  * its `Stage` parameter now takes in stage *objects* instead of XML strings. Use the new `New-BMPipelineStageObject`
  and `New-BMPipelineStageTargetObject` functions to create the objects you should pass.
  * it no longer returns the pipeline. Use the `PassThru` switch to have the pipeline object returned.

### Deprecated

#### Obsolete Functions

* The `Get-BMPackage` function. It is replaced by `Get-BMBuild`.
* The `New-BMPackage` function. It is replaced by `New-BMBuild`.
* The `Publish-BMReleasePackage` function. It is replaced by `Publish-BMReleaseBuild`.

#### Function Parameters

* The `Get-BMApplication` function's `Name` parameter. Use the new `Application` parameter instead.
* The `Get-BMApplicationGroup` function's `Name` parameter. Use the new `ApplicationGroup` parameter instead.
* The `Get-BMDeployment` function's `ID` parameter. Use the new `Deployment` parameter instead.
* The `Get-BMEnvironment` function's `Name` parameter. Use the new `Environment` parameter instead.
* The `Get-BMPipeline` function's `ApplicationID` parameter. Use the new `Application` parameter instead.
* The `Get-BMPipeline` function's `Name` parameter. Use the new `Pipeline` parameter instead.
* The `Get-BMServer` function's `Name` parameter. Use the new `Server` parameter instead.
* The `Get-BMServerRole` function's `Name` parameter. Use the new `ServerRole` parameter instead.
* The following parameters on `Get-BMVariable` and `Remove-BMVariable`:
  * `ApplicationName`; use `Application` instead.
  * `ApplicationGroupName`; use `ApplicationGroup` instead.
  * `EnvironmentName`; use `Environment` instead.
  * `ServerName`; use `Server` instead.
  * `ServerRoleName`; use `ServerRole` instead.
* The `New-BMApplication` function's `ApplicationGroupID` parameter. Use the new `ApplicationGroup` parameter instead.
* The `New-BMSession` function's `Uri` parameter. Use the new `Url` parameter instead.
* The `Remove-BMServer` function's `Name` parameter. Use the new `Server` parameter instead.

#### Object Properties

* The `Uri` property on session objects. Use the new `Url` property instead.
* The `Pipeline_Name` property on pipeline objects. Use the new `RaftItem_Name` property instead.
* The `Pipeline_Id` property on pipeline objects. Use the new `RaftItem_Id` property instead.

### Fixed

* `Invoke-BMRestMethod` (and by extension all the BuildMasterAutomation functions that call the API) no longer returns
`$null`.
* `Invoke-BMRestMethod` fails to log request body to the debug stream when using the `Body` parameter.

### Removed

* Removed the `Get-BMDeployment` function's `Build`, `Release`, and `Application` parameters. The BuildMaster
[Release and Build Deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build) no longer
supports getting deploys for builds, releases, and applications.
* `Get-BMPipeline` function's `ID` parameter. Use the `Name` parameter instead. BuildMaster pipelines no longer have
ids, just names.
* `New-BMApplication` function's `AllowMultipleActiveBuilds` switch. Its functionality was removed from BuildMaster.

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