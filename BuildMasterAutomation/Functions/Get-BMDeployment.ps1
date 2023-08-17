
function Get-BMDeployment
{
    <#
    .SYNOPSIS
    Gets a deployment from BuildMaster.

    .DESCRIPTION
    The `Get-BMDeployment` function gets a deployment from BuildMaster. Each parameter acts as an filter to the list
    of deployments returned. Only the deployments that match the provided parameters will be returnned.

    Pass the current BuildMaster session to the `Session` parameter.

    Pass the deployment id or deployment object to the `Deployment` parameter.

    Pass the application name, id, or object to the `Application` parameter.

    Pass the release nome, id, or object to the `Release` parameter.

    Pass the build nome, id, or object to the `Build` parameter.

    Pass the environment nome, id, or object to the `Environment` parameter.

    Pass the release number to the `ReleaseNumber` parameter.

    Pass the build number to the `BuildNumber` parameter.

    Pass the pipeline name to the `PipelineName` parameter.

    Pass the pipeline stage name to the `PipelineStageName` parameter.

    This function uses the
    [Release and Build Deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build).

    .EXAMPLE
    Get-BMDeployment -Session $session

    Demonstrates how to get all deployments from the instance of BuildMaster.

    .EXAMPLE
    Get-BMDeployment -Session $session -Deploytment $deployment

    Demonstrates how to get a specific deployment by passing a deployment object to the `Deployment` parameter. The
    `Get-BMDeployment` function looks for an `id` property on the object.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The deployment to get. You can pass a deployment id or object.
        [Alias('ID')]
        [Object] $Deployment,

        # The application to get deployments for. You can pass an application id, application name, or object.
        [Object] $Application,

        # The release to get deployments for. You can pass an release id, release name, or object.
        [Object] $Release,

        # The build to get deployments for. You can pass an build id, build name, or object.
        [Object] $Build,

        # The environment to get deployments for. You can pass an environment id, environment name, or object.
        [Object] $Environment,

        # The number for the release to get deployments for.
        [String] $ReleaseNumber,

        # The number for the build to get deployments for.
        [String] $BuildNumber,

        # The name of the pipeline to get deployments for.
        [String] $PipelineName,

        # The name of the pipeline stage to get deployments for.
        [String] $PipelineStageName,

        # The status of the deployments to get. Accepted values are 'pending', 'executing', 'succeeded', 'warned', or 'failed'
        [String] $Status
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false

        $parameter =
            @{ } |
            Add-BMObjectParameter -Name 'deployment' -Value $Deployment -PassThru |
            Add-BMObjectParameter -Name 'application' -Value $Application -PassThru |
            Add-BMObjectParameter -Name 'release' -Value $Release -PassThru |
            Add-BMObjectParameter -Name 'build' -Value $Build -PassThru |
            Add-BMObjectParameter -Name 'environment' -Value $Environment -PassThru

        if($ReleaseNumber)
        {
            $parameter['releaseNumber'] = $ReleaseNumber
        }
        if($BuildNumber)
        {
            $parameter['buildNumber'] = $BuildNumber
        }
        if($PipelineName)
        {
            $parameter['pipelineName'] = $PipelineName
        }
        if($PipelineStageName)
        {
            $parameter['pipelineStageName'] = $PipelineStageName
        }
        if($Status)
        {
            $valid = @('pending', 'executing', 'succeeded', 'warned', 'failed')
            if($Status -notin $valid)
            {
                $msg = "Unable to get deployment with status ${status} because it is not a valid input. Valid inputs " +
                       "for status are: $($valid -join ', ')."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            }
        }

        $deployments = @()
        Invoke-BMRestMethod -Session $Session -Name 'releases/builds/deployments' -Parameter $parameter -Method Post |
            Tee-Object -Variable 'deployments' |
            Write-Output

        if(-not $deployments)
        {
            $params = ($parameter.Keys | ForEach-Object { "$($_): $($parameter[$_])"}) -join ', '
            $msg = "Unable to get deployment with parameters ""$($params)"" because it does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}
