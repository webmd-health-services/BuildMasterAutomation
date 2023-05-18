
function New-BMRelease
{
    <#
    .SYNOPSIS
    Creates a new release for an application in BuildMaster.

    .DESCRIPTION
    The `New-BMRelease` function creates a release for an application in BuildMaster. It uses the BuildMaster
    [Release and Build Deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build).

    .EXAMPLE
    New-BMRelease -Session $session -Application 'BuildMasterAutomation' -Number '1.0' -Pipeline 'PowerShellModule'

    Demonstrates how to create a release using application/pipeline names. In this example, creates a `1.0` release for
    the `BuildMasterAutomation` application using the `PowerShellModule` pipeline.

    .EXAMPLE
    New-BMRelease -Session $session -Application 25 -Number '2.0' -Pipeline 'Deploy'

    Demonstrates how to create a release using an application id and pipeline name.. In this example, creates a `2.0`
    release for the application whose ID is `25` using the pipeline whose name is `Deploy`.

    .EXAMPLE
    New-BMRelease -Session $session -Application $app -Number '3.0' -Pipeline $pipeline

    Demonstrates how to create a release using application and pipeline objects. In this example, creates a `3.0`
    release for the application `$app` using the pipeline `$pipeline`.

    .EXAMPLE
    New-BMRelease -Session $session -Name 'BMA 1.0' -Application 'BuildMasterAutomation' -Number '1.0' -Pipeline 'PowerShellModule'

    Demonstrates how to create a release with a custom name. In this example, the release would be named `BMA 1.0`.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session object.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The application where the release should be created. Pass an application id, name, or object.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Application,

        # The release number, e.g. 1, 2, 3, 1.0, 2.0, etc.
        [Parameter(Mandatory)]
        [String] $Number,

        # The pipeline the release should use. Pass a pipeline name or object.
        [Object] $Pipeline,

        # The name of the release. By default, BuildMaster uses the release number, i.e. the value of the `Number`
        # parameter.
        [String] $Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $parameters = @{
            releaseNumber = $Number;
            releaseName = $Name;
        }

        # If $Pipeline is a string, then it's the pipeline name, so use it.
        if ($Pipeline | Test-BMName)
        {
            $parameters['pipelineName'] = $Pipeline
        }
        # If $Pipeline has an Application_Name property with a value, then the pipelin doesn't need the raft's naem as
        # a prefix.
        elseif ($Pipeline | Get-ObjectName -ObjectTypeName 'Application' -ErrorAction Ignore)
        {
            $parameters['pipelineName'] = $Pipeline | Get-BMObjectName -ObjectTypeName 'Pipeline'
        }
        # Pipeline is in a global raft, so its name has to be prefixed with the raft name.
        else
        {
            $raftName = Get-BMRaft -Raft $Pipeline | Get-BMObjectName -ObjectTypeName 'Raft'
            $pipelineName = $Pipeline | Get-ObjectName -ObjectTypeName 'Pipeline'
            $parameters['pipelineName'] = "$($raftName)::$($pipelineName)"
        }

        $parameters | Add-BMObjectParameter -Name 'application' -Value $Application

        Invoke-BMRestMethod -Session $Session -Name 'releases/create' -Method Post -Parameter $parameters
    }
}
