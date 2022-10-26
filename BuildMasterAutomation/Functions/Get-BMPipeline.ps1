
function Get-BMPipeline
{
    <#
    .SYNOPSIS
    Gets pipelines from BuildMaster.

    .DESCRIPTION
    The `Get-BMPipeline` function gets all pipelines. You can filter the list of pipelines by raft, pipeline name, and
    application by using the `Raft`, `Pipeline`, and `Application` parameters, respectively. To get only pipelines in a
    specific raft, pass the raft id or a raft object to the `Raft` parameter. To get a specific pipeline, pass its name
    or a pipeline object to the `Pipeline` parameter. To get pipelines for a specific application, pass the
    application id or application object to the `Application` parameter. If using multiple filter parameters, only
    pipelines that match all the filter parameters are returned.

    To search for a pipeline using a wildcard, pass a wildcard pattern to the `Pipeline` parameter.

    This function uses the `Rafts_GetRaftItems` native API method.

    .EXAMPLE
    Get-BMPipeline -Session $session -Raft $raft

    Demonstrates how to get all the pipelines across all rafts and applications.

    .EXAMPLE
    Get-BMPipeline -Session $session -Raft $raft

    Demonstrates how to get all the pipelines for a specific raft.

    .EXAMPLE
    Get-BMPipeline -Session $session -Pipeline 'BuildMaster Automation'

    Demonstrates how to get pipelines by name. If there are multiple pipelines across rafts and applications with the
    same name, they will all be returned.

    .EXAMPLE
    Get-BMPipeline -Session $session -Pipeline '*Automation'

    Demonstrates that you can use wildcards in the `Name` parameter's value to search for pipelines.

    .EXAMPLE
    Get-BMPipeline -Session $session -Raft $raft -Application 39

    Demonstrates how to get a specific application's pipelines stored in a specific raft.

    .EXAMPLE
    Get-BMPipeline -Session $session -Raft $raft -Application $app -Pipeline 'Pipeline 2'

    Demonstrates how to get an application's pipeline using an application object and the pipeline's name.
    #>
    [CmdletBinding()]
    param(
        # A session object to BuildMaster. Use the `New-BMSession` function to creates a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The raft in which to search for the pipeline.
        [Object] $Raft,

        # The pipeline to get. Pass a pipeline name (wildcards supported), or a pipeline object.
        [Parameter(ValueFromPipeline)]
        [Object] $Pipeline,

        # The application whose pipelines to get. Passing application ids or objects are supported.
        [Object] $Application
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Get-BMRaftItem -Session $session `
                       -Raft $Raft `
                       -RaftItem $Pipeline `
                       -Application $Application `
                       -TypeCode ([BMRaftItemTypeCode]::Pipeline) |
            Add-BMPipelineMember -PassThru
    }
}
