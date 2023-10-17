
function Get-BMDeployment
{
    <#
    .SYNOPSIS
    Gets a deployment from BuildMaster.

    .DESCRIPTION
    The Get-BMDeployment function gets deployments from BuildMaster. Pass a deployment ID to the Deployment parameter to
    get a single deployment. To filter for one or more deployments, pass the criteria to filter by to the rest of the
    parameters. Each parameter is combined into a logical "AND" that is used to filter for deployments. Only the
    deployments that match all the parameters are returned.

    Pass the current BuildMaster session to the `Session` parameter.

    Pass the deployment id or deployment object to the `Deployment` parameter.

    Pass the application name, id, or object to the `Application` parameter.

    Pass the release name, id, or object to the `Release` parameter.

    Pass the build name, id, or object to the `Build` parameter.

    Pass the environment name, id, or object to the `Environment` parameter.

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
        [Parameter(Mandatory, ParameterSetName='ById')]
        [Alias('ID')]
        [Object] $Deployment,

        # The application to get deployments for. You can pass an application id, application name, or application object.
        [Parameter(ParameterSetName='ByFilter')]
        [Object] $Application,

        # The release to get deployments for. You can pass an release id, release name, or release object.
        [Parameter(ParameterSetName='ByFilter')]
        [Object] $Release,

        # The build to get deployments for. You can pass an build id, build name, build number, or build object.
        [Parameter(ParameterSetName='ByFilter')]
        [Object] $Build,

        # The environment to get deployments for. You can pass an environment id, environment name, or environment object.
        [Parameter(ParameterSetName='ByFilter')]
        [Object] $Environment,

        # The name of the pipeline to get deployments for.
        [Parameter(ParameterSetName='ByFilter')]
        [String] $Pipeline,

        # The name of the pipeline stage to get deployments for.
        [Parameter(ParameterSetName='ByFilter')]
        [String] $Stage,

        # The status of the deployments to get. Accepted values are 'pending', 'executing', 'succeeded', 'warned', or 'failed'.
        [Parameter(ParameterSetName='ByFilter')]
        [ValidateSet('pending', 'executing', 'succeeded', 'warned', 'failed')]
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
            Add-BMObjectParameter -Name 'environment' -Value $Environment -PassThru |
            Add-BMObjectParameter -Name 'release' -Value $Release -PassThru

        if($Build)
        {
            if ($Build -is [string] -and -not [Int64]::TryParse($Build, [ref] $Build))
            {
                $parameter['buildNumber'] = $Build
            }
            else
            {
                $parameter = $parameter | Add-BMObjectParameter -Name 'build' -Value $Build -PassThru
            }
        }

        if($Pipeline)
        {
            $parameter['pipelineName'] = $Pipeline
        }
        if($Stage)
        {
            $parameter['pipelineStageName'] = $Stage
        }
        if($Status)
        {
            $parameter['status'] = $Status
        }

        $deployments = @()
        Invoke-BMRestMethod -Session $Session -Name 'releases/builds/deployments' -Parameter $parameter -Method Post |
            Tee-Object -Variable 'deployments' |
            Write-Output

        if (-not $deployments)
        {
            if ($PSCmdlet.ParameterSetName -eq 'ById')
            {
                $msg = "Unable to get deployment ""$($Deployment | Get-BMObjectName)"" because it does not exist."
            }
            else
            {
                $params = ($parameter.Keys | ForEach-Object { "$($_) = $($parameter[$_])"}) -join ', '
                $msg = "No deployments exist that match: ""$($params)""."
            }

            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}
