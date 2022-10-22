
function Get-BMRelease
{
    <#
    .SYNOPSIS
    Gets the release for an application in BuildMaster.

    .DESCRIPTION
    The `Get-BMRelease` function gets releases in BuildMaster. It uses the
    [Release and Build Deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build).

    To get a specific release, pass a release object, release ID, or release name to the `Release` parameter. If the
    release doesn't exist, the function will write an error.

    To get all the releases for a specific application, pass an application object, application ID, or application name
    to the `Application` parameter. You can get a specific application's release by passing the release's name to the
    `Name` parameter.

    .EXAMPLE
    Get-BMRelease -Session $session -Release $release

    Demonstrates how to get a specific release by passing a release object to the `Release` parameter. The
    `Get-BMRelease` function looks for an `id` or `name` property on the object.

    .EXAMPLE
    Get-BMRelease -Session $session -Application $app

    Demonstrates how to get all the releases for an application by passing an application object to the `Application`
    parameter. The application object must have a`Application_Id`, `id`, `Application_Name`, or `name` properties.

    .EXAMPLE
    Get-BMRelease -Session $session -Application 34

    Demonstrates how to get all the releases for an application by passing its ID to the `Application` parameter.

    .EXAMPLE
    Get-BMRelease -Session $session -Application 'BuildMasterAutomation'

    Demonstrates how to get all the releases for an application by passing its name to the `Application` parameter.

    .EXAMPLE
    Get-BMRelease -Session $session -Application 'BuildMasterAutomation' -Name '4.1'

    Demonstrates how to get a specific release for an application by passing the release's name to the `Name` parameter.
    In this example, the '4.1' release will be returned, if it exists.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The release to get. Pass a release id, name, or object.
        [Parameter(ValueFromPipeline)]
        [Alias('Name')]
        [Object] $Release,

        # The application whose releases to get. Pass an application id, name, or object.
        [Object] $Application
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false

        if ($Application -and -not ($Application | Get-BMApplication -Session $Session))
        {
            return
        }

        $parameter =
            @{} |
            Add-BMObjectParameter -Name 'release' -Value $Release -PassThru |
            Add-BMObjectParameter -Name 'application' -Value $Application -PassThru

        $releases = @()
        Invoke-BMRestMethod -Session $Session -Name 'releases' -Parameter $parameter -Method Post |
            Tee-Object -Variable 'releases' |
            Write-Output

        if ($Release -and -not $releases)
        {
            $appMsg = ''
            if ($Application)
            {
                $appMsg = " in application ""$($Application | Get-BMObjectName)"""
            }

            $msg = "Release ""$($Release | Get-BMObjectName)""$($appMsg) does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}