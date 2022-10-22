
function Get-BMDeployment
{
    <#
    .SYNOPSIS
    Gets a deployment from BuildMaster.

    .DESCRIPTION
    The `Get-BMDeployment` function gets deployments in BuildMaster. It uses the
    [Release and Build Deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build).

    To get a specific deployment, pass a deployment ID. If it doesn't exist, an error will be written.

    To get all the deployments for a specific build, pass a build id, name, or object to the `Build` parameter. If the
    build doesn't exist, an error will be written.

    To get all the deployments for a specific release, pass a release id, name, or object to the `Release` parameter. If
    the release doesn't exist, an error will be written.

    To get all the deployments for a specific application, pass an application id, name, or object to the `Application`
    parameter. If the application does not exist, an error will be written.

    .EXAMPLE
    Get-BMDeployment -Session $session

    Demonstrates how to get all deployments from the instance of BuildMaster.

    .EXAMPLE
    Get-BMDeployment -Session $session -ID $deployment

    Demonstrates how to get a specific deployment by passing a deployment object to the `Deployment` parameter. The
    `Get-BMDeployment` function looks for an `id` property on the object.

    .EXAMPLE
    Get-BMDeployment -Session $session -Build $build

    Demonstrates how to get all deployments for a build by passing a build object to the `Build` parameter. The
    `Get-BMDeployment` function looks for an `id` or `number` property on the object.

    .EXAMPLE
    Get-BMDeployment -Session $session -Release $release

    Demonstrates how to get all deployments for a release by passing a release object to the `Release` parameter. The
    `Get-BMDeployment` function looks for an `id` or `name` property on the object.

    .EXAMPLE
    Get-BMDeployment -Session $session -Application $app

    Demonstrates how to get all deployments for an application by passing an application object to the `Application`
    parameter. The `Get-BMDeployment` function looks for an `id` or `name` property on the object.

    .EXAMPLE
    Get-BMDeployment -Session $session -Application 34

    Demonstrates how to get all deployments for an application by passing its ID to the `Application` parameter.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The deployment to get. You can pass a deployment id or object.
        [Parameter(Mandatory, ParameterSetName='ByDeployment')]
        [Object] $Deployment,

        # The build whose deployments to get. You can pass a build id or object.
        [Parameter(Mandatory, ParameterSetName='ByBuild')]
        [Object] $Build,

        # The release whose deployments to get. You can pass a release id or object.
        [Parameter(Mandatory, ParameterSetName='ByRelease')]
        [Object] $Release,

        # The application whose deployments to get. You can pass an application id or object.
        [Parameter(Mandatory, ParameterSetName='ByApplication')]
        [Object] $Application
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $parameter = @{ }
        if( $PSCmdlet.ParameterSetName -eq 'ByDeployment' )
        {
            $parameter | Add-BMObjectParameter -Name 'deployment' -Value $Deployment
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'ByBuild' )
        {
            if (-not ($Build | Get-BMBuild -Session $session -ErrorAction Ignore))
            {
                $msg = "Failed to get deployments for build ""$($Build | Get-BMObjectName) because that build does " +
                       'not exist'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }

            if (-not ($Build | Test-BMObject))
            {
                $parameter['buildNumber'] = $Build
            }
            else
            {
                $parameter | Add-BMObjectParameter -Name 'build' -Value $Build
            }
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'ByRelease' )
        {
            if (-not ($Release | Get-BMRelease -ErrorAction Ignore))
            {
                $msg = "Failed to get deployments for release ""$($Release | Get-BMObjectName)"" because that " +
                       'release does not exist.'
                Write-Error -message $msg -ErrorAction $ErrorActionPreference
                return
            }
            $parameter | Add-BMObjectParameter -Name 'release' -Value $Release
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'ByApplication' )
        {
            if (-not ($Application | Get-BMApplication -ErrorAction Ignore))
            {
                $msg = "Failed to get deployments for application ""$($Application | Get-BMObjectName)"" because " +
                       'that application does not exist.'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            }
            $parameter | Add-BMObjectParameter -Name 'application' -Value $Application
        }

        $deployments = @()
        Invoke-BMRestMethod -Session $Session -Name 'releases/builds/deployments' -Parameter $parameter -Method Post |
            Tee-Object -Variable 'deployments' |
            Write-Output

        if ($PSCmdlet.ParameterSetName -eq 'ByDeployment' -and -not $deployments)
        {
            $msg = "Unable to get deployment ""$($deployment | Get-BMObjectName)"" because it does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}
