
function Get-BMRelease
{
    <#
    .SYNOPSIS
    Gets the release for an application in BuildMaster.

    .DESCRIPTION
    The `Get-BMRelease` function gets the releases for an application in BuildMaster. It uses the [Release and Package Deployment API](http://inedo.com/support/documentation/buildmaster/reference/api/release-and-package). 

    .EXAMPLE
    Get-BMRelease -Session $session -Release $release

    Demonstrates how to get a specific release by passing a release object to the `Release` parameter. The `Get-BMRelease` function looks for an `id` or `name` property on the object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A session object that contains the settings to use to connect to BuildMaster. Use `New-BMSession` to create session objects.
        $Session,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object]
        # The release to get. You can pass:
        #
        # * A release object. It must have either an `id` or `name` parameter.
        # * The release ID as an integer.
        # * The release name as a string.
        $Release
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $parameter = @{ } | Add-BMObjectParameter -Name 'release' -Value $Release -PassThru
        Invoke-BMRestMethod -Session $Session -Name 'releases' -Parameter $parameter              
    }
}