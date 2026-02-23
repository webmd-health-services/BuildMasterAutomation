
function New-BMRelease
{
    <#
    .SYNOPSIS
    Creates a new release in a BuildMaster application.

    .DESCRIPTION
    The `New-BMRelease` function creates a release in a BuildMaster application in BuildMaster. Pass the release's
    application's ID, name, or object to the `Application` parameter. Pass the release number to the `Number` parameter.
    Pass the release's deployment pipeline ID, name, or object to the `Pipeline` parameter. You can optionally pass a
    release name to the `Name` parameter.

    When passing a pipeline name, that name must be a unique pipeline name across all global pipelines and the
    application's pipelines. If there are multiple pipelines with the same name, the function writes an error. To avoid
    the error, pass the pipeline ID or pipeline object instead of a name.

    This functoin uses the BuildMaster [Release and Build Deployment
    API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build).

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

        # The pipeline the release should use. Pass a pipeline ID, name, or object. When passing a pipeline name, if
        # there is a global pipeline and application pipeline with that name, the function writes an error and doesn't
        # create the release. To avoid this error, pass pipeline IDs or pipeline objects.
        [Parameter(Mandatory)]
        [Object] $Pipeline,

        # The name of the release. By default, BuildMaster uses the release number, i.e. the value of the `Number`
        # parameter.
        [String] $Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $Application = Get-BMApplication -Session $Session -Application $Application
        if (-not $Application)
        {
            return
        }

        $appName = $Application.Application_Name

        $pipelinesById = & {
                $Pipeline | Get-BMPipeline -Session $Session -ErrorAction Ignore | Write-Output
                $Pipeline |
                    Get-BMPipeline -Session $Session -Application $Application -ErrorAction Ignore |
                    Write-Output
            } |
            Group-Object -Property 'RaftItem_Id'

        $pipelineCount = ($pipelinesById | Measure-Object).Count
        if ($pipelineCount -eq 0)
        {
            $pipelineNameMsg = """$($Pipeline | Get-BMObjectName -ObjectTypeName 'RaftItem')"""
            if (($Pipeline | Test-BMID))
            {
                $pipelineNameMsg = $Pipeline
            }

            $msg = "Failed to create release ""${Number}"" in application ""${appName}"" because pipeline " +
                   "${pipelineNameMsg} does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        if ($pipelineCount -gt 1)
        {
            $pipelineNameMsg =
                $pipelinesById.Group | Select-Object -First 1 | Get-BMObjectName -ObjectTypeName 'RaftItem'
            $msg = "Failed to create release ""${Number}"" in application ""${appName}"" because there are "  +
                   "${pipelineCount} ""${pipelineNameMsg}"" pipelines. When duplicate pipelines exist by name, pass " +
                   'a pipeline object or pipeline ID to New-BMRelease.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $Pipeline = $pipelinesById.Group | Select-Object -First 1

        if ($Pipeline.Application_Id -and $Pipeline.Application_Id -ne $Application.Application_Id)
        {
            $msg = "Failed to create release ""${Number}"" because the ""$($Pipeline.RaftItem_Name)"" pipeline is " +
                   "assigned to application ""$($Pipeline.Application_Name)"" and is not assigned to the release's " +
                   "application ""$($Application.Application_Name)""."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $pipelineName = $Pipeline.RaftItem_Name
        # If the pipeline isn't in an application, it must be prefixed with the pipeline's raft prefix.
        if (-not $Pipeline.Application_Id)
        {
            $raft = Get-BMRaft -Session $Session -Raft $Pipeline.Raft_Id
            $pipelineName = "$($raft.Raft_Prefix)::${pipelineName}"
        }

        $parameters = @{
            releaseNumber = $Number
            releaseName = $Name
            pipelineName = $pipelineName
            applicationId = $Application.Application_Id
        }

        Invoke-BMRestMethod -Session $Session -Name 'releases/create' -Method Post -Parameter $parameters
    }
}
