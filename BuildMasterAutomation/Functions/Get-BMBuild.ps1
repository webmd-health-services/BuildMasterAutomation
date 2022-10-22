
function Get-BMBuild
{
    <#
    .SYNOPSIS
    Gets a build from BuildMaster.

    .DESCRIPTION
    The `Get-BMBuild` function gets a build from BuildMaster. With no parameters, it returns all builds. To get all the
    builds that are part of a release, pass a release id or object to the `Release` parameter. To get a specific build,
    pass a build id or object to the `Build` parameter.

    This function uses BuildMaster's
    [Release and Build Deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build).

    .EXAMPLE
    Get-BMBuild -Session $session

    Demonstrates how to get all builds.

    .EXAMPLE
    Get-BMBuild -Session $session -Build $build

    Demonstrates how to get a specific build using a build object.

    .EXAMPLE
    Get-BMBuild -Session $session -Build 500

    Demonstrates how to get a specific build using its id.

    .EXAMPLE
    Get-BMBuild -Session $session -Release $release

    Demonstrates how to get all the builds that are part of a release using a release object.

    .EXAMPLE
    Get-BMBuild -Session $session -Release 438

    Demonstrates how to get all the builds that are part of a release using the release's id.
    #>
    [CmdletBinding(DefaultParameterSetName='AllBuilds')]
    param(
        # A session object to BuildMaster. Use the `New-BMSession` function to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The build to get. Can be a build id or object.
        [Parameter(Mandatory, ParameterSetName='SpecificBuild')]
        [Object] $Build,

        # The release whose builds to get. Can be a release id or object.
        [Parameter(Mandatory, ParameterSetName='ReleaseBuilds')]
        [Object] $Release
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameter = @{}
    if( $PSCmdlet.ParameterSetName -eq 'SpecificBuild' )
    {
        $parameter | Add-BMObjectParameter -Name 'build' -Value $Build
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'ReleaseBuilds' )
    {
        $release = $Release | Get-BMRelease -Session $session
        if (-not $release)
        {
            $msg = "Failed to get builds for release ""$($Release | Get-BMObjectName)"" because the release does not " +
                   'exist.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }
        $parameter | Add-BMObjectParameter -Name 'release' -Value $Release
    }

    $parameterParam = @{ }
    if ($parameter.Count)
    {
        $parameterParam['Parameter'] = $parameter
    }

    $builds = @()
    Invoke-BMRestMethod -Session $Session -Name 'releases/builds' @parameterParam -Method Post |
        Where-Object {
            # There's a bug in BuildMaster's API that returns builds for multiple releases. We don't want this.
            if( $PSCmdlet.ParameterSetName -eq 'ReleaseBuilds' )
            {
                return $_.releaseId -eq $parameter.releaseId
            }
            return $true
        } |
        Tee-Object -Variable 'builds' |
        Write-Output

    if ($PSCmdlet.ParameterSetName -eq 'SpecificBuild' -and -not $builds)
    {
        $msg = "Build ""$($Build | Get-BMObjectName -PropertyName 'buildNumber')"" does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
    }
}
