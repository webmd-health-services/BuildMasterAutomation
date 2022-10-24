# BuildMasterAutomation Changelog

## 2.0.0

### Known Issues

* `Get-BMVariable` doesn't work for application or application group variables due to a bug in BuildMaster.

### Upgrade Instructions

***This release contains breaking changes. Please read these upgrade instructions carefully before upgrading.***

This release adds support for BuildMaster 6.2.33, which contains breaking changes from version 6.1.

* Rename usages of the `Get-BMDeployment` function's `Package` parameter to `Build`.
* Rename usages of the `Get-BMPipeline` function's `ApplicationID` parameter to `Application`.
* Remove usages of the `New-BMApplication` function's `AllowMultipleActiveBuilds` switch. This functionality was
removed from BuildMaster.
* Rename usages of `New-BMPipeline` to `Set-BMPipeline`.
* Update values passed to the `Set-BMPipeline` (née `New-BMPipeline`) function's `Stage` parameter. This parameter now
requires an array of stage objects, which can be created with the new `New-BMPipelineStageObject` function.
* Rename usages of `Get-BMPackage` to `Get-BMBuild`.
* Rename usages of the `Get-BMBuild` (née `Get-BMPackage`) function's `Package` parameter to `Build`.
* Rename usages of the `Get-BMDeployment` function's `ID` parameter to `Deployment`.
* Remove usages of the `Get-BMPipeline` function's `ID` parameter. BuildMaster pipelines no longer have ids, just
names.
* Rename usages of the `Get-BMPipeline` function's `Name` parameter to `Pipeline`.
* Update usages of the `Get-BMPipeline` function to pass a pipeline name or pipeline object to the `Pipeline` parameter
instead of an id.
* Rename usages of the `Get-BMPipeline` function's `ApplicationID` parameter to `Application`.
* Objects returned by `Get-BMPipeline` are now raft item objects. Check usages to ensure you're using correct
properties.
* Rename usages of the `New-BMApplication` function's `ApplicationGroupID` parameter to `ApplicationGroup`.
* Rename usages of the `New-BMPackage` function to `New-BMBuild`.
* Rename usages of the `Publish-BMReleasePackage` function to `Publish-BMReleaseBuild`.
* Rename usages of the `Publish-BMReleaseBuild` (née `Publish-BMReleasePackage`) function's `Package` parameter to
`Build`.
* `Set-BMPipeline` (née `New-BMPipeline`) now creates *or* updates a pipeline. Inspect usages to see the impact of this
new behavior.
* Update usages of the `Set-BMPipeline` (née `New-BMPipeline`) function's `Stage` parameter to pass stage objects
instead of strings of XML. Use the new `New-BMPipelineStageObject` and `New-BMPipelineStageTargetObject` functions to
create the objects you should pass.
* Update usages of the `Set-BMPipeline` (née `New-BMPipeline`) function that use the return value. `Set-BMPipeline` no
longer returns the pipeline object by default. Use the new `PassThru` switch and the pipeline object will be returned.
* Rename usages of the `New-BMSession` function's `Uri` parameter to `Url`.
* Add `-ErrorAction Ignore` to usages of `Remove-BMServer`, `Remove-BMServerRole`, and `Remove-BMVariable` if you
don't care if the item doesn't exist. These functions now write errors when the item to remove doesn't exist.
* Rename usages of the `Disable-BMEnvironment` and `Enable-BMEnvironment` functions' `Name` parameter to
`EnvironmentName`.
* Rename usages of the `Get-BMApplication` function's `Name` parameter to `Application`.
* Add `-ErrorAction Ignore` to usages of `Get-BMApplication` if the usage doesn't care if no application is returned.
`Get-BMApplication` writes an error if an application doesn't exist.
* Rename usages of the `Get-BMApplicationGroup` function's `Name` parameter to `ApplicationGroup`.
* Add `-ErrorAction Ignore` to usages of `Get-BMApplication`, `Get-BMApplicationGroup`, `Get-BMBuild` (née
`Get-BMPackage`), `Get-BMDeployment`, `Get-BMPipeline`, `Get-BMRelease`, `Get-BMServer`, `Get-BMServerRole`, and
`Get-BMVariable`  that request a specific item and that are not searching with a wildcard pattern. These functions now each write an error if a requested item doesn't exist.
* Add `-ErrorAction Ignore` to usages of `Get-BMBuild` (née `Get-BMPackage`) when searching for a build in a specific
release and that release might not exist. The function now writes an error if the release doesn't exist.
* Add `-ErrorAction Ignore` to usages of `Get-BMDeployment` when getting deployments for a build, release, or
application and the build, release, or application might not exist. The function now writes an error if the build,
release, or application don't exist.
* Rename usages of the `Get-BMEnvironment` function's `Name` parameter to `Environment`.
* Rename usages of the `Get-BMRelease` function's `Name` parameter to `Release`.
* Add `-ErrorAction Ignore` to usages of the `Get-BMRelease` function the request releases for an application and the
usage doesn't care if the application doesn't exist. The function now writes an error when the application doesn't
exist.
* Rename usages of the `Get-BMServer` function's `Name` parameter to `Server`.
* Rename usages of the `Get-BMServerRole` function's `Name` parameter to `ServerRole`.
* Rename usages of the `Get-BMVariable` function's `Name` parameter to `Variable`.
* Rename usages of the `Get-BMVariable` and `Remove-BMVariable` function's `ApplicationName`, `ApplicationGroupName`,
`EnvironmentName`, `ServerName`, and `ServerRoleName` parameters to `Application`, `ApplicationGroup`, `Environment`,
`Server`, and `ServerRole`, respectively.
* Add `-ErrorAction Ignore` to usages of `Get-BMVariable` function's `Application` (née `ApplicationName`),
`ApplicationGroup` (née `ApplicationGroupName`), `Environment` (née `EnvironmentName`), `Server` (née `ServerName`), and
`ServerRole` (née `ServerRole`) where an item migh not exist. `Get-BMVariable` now writes an error if the requested item
doesn't exist.
* Rename usages of the `New-BMApplication` function's `ApplicationGroupId` parameter to `ApplicationGroup`.
* Add `-ErrorAction Ignore` to usages of `New-BMApplication` where the application might already exist. The function now
writes an error if an application exists.
* Rename usages of the `New-BMBuild` (née `New-BMPackage`) function's `PackageNumber` parameter to `BuildNumber`.
* Rename usages of the `New-BMSession` function's `Uri` parameter to `Url`.
* Rename usages of the `Remove-BMServer` function's `Name` parameter to `Server`.
* Rename usages of the `Set-BMRelease` function's `PipelineID` parameter to `Pipeline`.

### Added

* Function `Add-BMParameter`, for adding values to a parameter hashtable (i.e. a hashtable that will be used as the body
of a request to a BuildMaster API endpoint). If the value is `$null`, however, it won't be added.
* Function `ConvertFrom-BMNativeApiByteValue` for converting `byte[]` values returned by the BuildMaster native API
into their original strings.
* Function `ConvertTo-BMNativeApiByteValue` for converting string values that need to be sent as `byte[]` parameters to
the BuildMaster native APIs.
* Function `Get-BMObjectName` for getting the name of an object that was returned by the BuildMaster API.
* Function `Get-BMRaft` for getting all rafts.
* Function `Get-BMRaftItem` for getting raft items.
* Function `New-BMPipelinePostDeploymentOptionsObject` for creating a post-deployment options object to use when
creating a pipeline.
* Function `New-BMPipelineStageObject` for creating a stage object that can be passed to the `Set-BMPipeline` (née
`New-BMPipeline`) function's `Stage` parameter.
* Function `New-BMPipelineStageTargetObject` for creating a target object that can be passed to the
`New-BMPipelineStageObject` function's `Target` parameter.
* Function `Remove-BMApplication` function for deleting applications.
* Function `Remove-BMPipeline` function for removing pipelines.
* Function `Remove-BMRaftItem` function for deleting raft items.
* Parameter `PostDeploymentOption` to the `Set-BMPipeline` (née `New-BMPipeline`) function for configuring a pipeline's
post-deployment options. Use the `New-BMPipelinePostDeploymentOptionsObject` to create a post-deployment options object.
* Parameter `EnforceStageSequence` to the `Set-BMPipeline` (née `New-BMPipeline`) function for controlling the
pipeline's stage sequence enforcement.
* Function `Set-BMRaftItem` for creating and/or updating a raft item.
* Parameter `PassThru` to the `Set-BMPipeline` (née `New-BMPipeline`) function for returning the created/updated
pipeline object.
* Parameter `AsName` to `Add-BMObjectParameter` to only set a parameter from an object's name, ignoring any ids.
* Renamed `Disable-BMEnvironment` function's `Name` parameter to `Environment`, and changed it to accept an environment
name, id, or environment object.
* Renamed `Enable-BMEnvironment` function's `Name` parameter to `Environment`, and changed it to accept an environment
name, id, or environment object.
* `Get-BMApplication` now accepts application ids, names, or application objects from the pipeline.
* `Get-BMApplicationGropup` now accepts application group ids, names, or application group objects from the pipeline.
* `Get-BMEnvironment` now accepts environment ids, names, or application objects from the pipeline.
* `Get-BMPipeline` now accepts pipeline names or pipeline objects from the pipeline.
* `Get-BMServer` and `Remove-BMServer` now accept server ids, names or server objects from the pipeline.
* `Get-BMServerRole` and `Remove-BMServerRole` now accept server role ids, names or server role objects from the
pipeline.
* `Get-BMVariable` and `Remove-BMVariable` now accept variable ids, names or variable objects from the pipeline.
* Function `New-BMPipelinePostDeploymentOptionsObject` for creating an object that can be passed to the `Set-BMPipeline`
(née `New-BMPipeline`) function's new `PostDeploymentOption` parameter.

### Changed

* The `Add-BMObjectParameter` function now accepts `$null` values. When passed a null value, it does nothing.
* The `Get-BMPipeline` function's `ApplicationID` parameter renamed to `Application`, and updated to accept application
objects, names, and ids.
* Renamed `Get-BMPackage` to `Get-BMBuild`.
* Renamed usages of the `Get-BMBuild` (née `Get-BMPackage`) function's `Package` parameter to `Build`.
* Renamed `Get-BMDeployment` function's `ID` parameter to `Deployment` and updated it to also accept deployment
objects.
* `Get-BMPipeline` function returns raft item objects instead of pipeline objects.
* Renamed `New-BMApplication` function's `ApplicationGroupID` parameter to `ApplicationGroup` and updated it to
accept an application group id or object.
* Renamed `New-BMPackage` function to `New-BMBuild`.
* Renamed the `New-BMBuild` (née `New-BMPackage)` function's `PackageNumber` parameter to `BuildNumber`.
* Renamed the `Publish-BMReleasePackage` function to `Publish-BMReleaseBuild`.
* Renamed the `Publish-BMReleaseBuild` (née `Publish-BMReleasePackage`) function's `Package` parameter to `Build`.
* Renamed the `New-BMPipeline` function to `Set-BMPipeline` and updated it to create and/or update the pipeline.
* The `Set-BMPipeline` (née `New-BMPipeline`) function's `Stage` parameter to take in stage objects instead of XML
strings. Use the new `New-BMPipelineStageObject` and `New-BMPipelineStageTargetObject` functions to create the objects
you should pass.
* `Set-BMPipeline` (née `New-BMPipeline`) no longer returns the pipeline. Use the `PassThru` switch to have the pipeline
object returned.
* Renamed the `New-BMSession` function's `Uri` parameter to `Url`.
* `Remove-BMServer`, `Remove-BMServerRole`, and `Remove-BMVariable` now write an error when the item to delete doesn't
exist. Use `-ErrorAction Ignore` to ignore if the item exists or not.
* Renamed the `Get-BMApplication` function's `Name` parameter to `Application` and updated it to accept application
names, ids, or application objects.
* The `Get-BMApplication` function now accepts wildcards in application names.
* The `Get-BMApplication`, `Get-BMApplicationGroup`, `Get-BMBuild` (née `Get-BMPackage`), `Get-BMDeployment`,
`Get-BMEnvironment`, `Get-BMPipeline`, `Get-BMRelease`, `Get-BMServer`, and `Get-BMServerRole` functions now each write an error when
getting a specific item and the item does not exist, unless searching with a wildcard pattern. Use
`-ErrorAction Ignore` to ignore if an item doesn't exist.
* The `Get-BMBuild` (née `Get-BMPackage`) function now writes an when searching for a build in a specific release and
that release doesn't exist. Use `-ErrorAction Ignore` to ignore the error.
* The `Get-BMDeployment` now writes an error when getting deployments for a build, release, or application and the
build, release, or application might not exist. Use `-ErrorAction Ignore` to ignore the error.
* Renamed the `Get-BMEnvironment` function's `Name` parameter to `Environment` and updated to accept environment ids,
names, and environment objects.
* The `Get-BMRelease` function now writes an error when requesting releases for an application and the application
doesn't exist. Use `-ErrorAction Ignore` to ignore the error.
* Renamed the `Get-BMServer` function's `Name` parameter to `Server`, and updated it to accept server ids, names, and
server objects.
* Renamed the `Get-BMServerRole` function's `Name` parameter to `ServerRole`, and updated it to accept server ids,
names, and server objects.
* Renamed the `Get-BMVariable` function's `Name` parameter to `Variable`, and updated it to accept variable ids, names,
and variable objects.
* Renamed the `Get-BMVariable` and `Remove-BMVariable` function's `ApplicationName`, `ApplicationGroupName`,
`EnvironmentName`, `ServerName`, and `ServerRoleName` parameters to `Application`, `ApplicationGroup`, `Environment`,
`Server`, and `ServerRole`, respectively, and updated each to accept item ids, names, and objects.
* Renamed the `New-BMApplication` function's `ApplicationGroupId` parameter to `ApplicationGroup`, and updated it to
accept application group ids, names, and application group objects.
* The `New-BMApplication` function now writes an error if an application already exists. Use `-ErrorAction Ignore` to
ignore the error.
* Renamed the `New-BMSession` function's `Uri` parameter to `Url`. URI's to BuildMaster are always URLs.
* Renamed the `Remove-BMServer` function's `Name` parameter to `Server` and updated it to accept server ids, names, and
server objects.
* Renamed the `Remove-BMServerRole` function's `Name` parameter to `ServerRole` and updated it to accept server ids,
names, and server objects.
* Renamed the `Set-BMRelease` function's `PipelineID` parameter to `Pipeline` and updated it to accept pipeline ids,
names, or pipeline objects.

### Deprecated

### Fixed

* `Invoke-BMRestMethod` (and by extension all the BuildMasterAutomation functions that call the API) no longer returns
`$null`.
* `Set-BMRelease` fails when using `-ErrorAction Ignore` to ignore when a release doesn't exist.
* `Invoke-BMRestMethod` fails to log request body to the debug stream when using the `Body` parameter.

### Removed

* `New-BMApplication` function's `AllowMultipleActiveBuilds` switch. Its functionality was removed from BuildMaster.
* `Get-BMPipeline` function's `ID` parameter. Use the `Name` parameter instead. BuildMaster pipelines no longer have
ids, just names.
* The `Get-BMRelease` function's `Name` parameter. Use the `Release` parameter instead (which accepts release names).

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