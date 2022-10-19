
function Get-BMPipeline
{
    <#
    .SYNOPSIS
    Gets pipelines from BuildMaster.

    .DESCRIPTION
    The `Get-BMPipeline` function gets pipelines. By default, it returns all pipelines. To get a specific pipeline, pass
    its name to the `Name` parameter. The `Name` parameter supports wildcards. To get a specific application's
    pipelines, pass the application's id or object to the `Application` parameter.

    This function uses the `Rafts_GetRaftItems` native API method.

    .EXAMPLE
    Get-BMPipeline -Session $session

    Demonstrates how to get all the pipelines.

    .EXAMPLE
    Get-BMPipeline -Session $session -Name 'BuildMaster Automation'

    Demonstrates how to get pipelines by name. If there are multiple pipelines with the same name, they will all be
    returned.

    .EXAMPLE
    Get-BMPipeline -Session $session -Name '*Automation'

    Demonstrates that you can use wildcards in the `Name` parameter's value to search for pipelines.

    .EXAMPLE
    Get-BMPipeline -Session $session -Application 39

    Demonstrates how to get a specific application's pipelines.

    .EXAMPLE
    Get-BMPipeline -Session $session -Application $app -Name 'Pipeline 2'

    Demonstrates how to get an application's pipeline using an application object and the pipeline's name.
    #>
    [CmdletBinding()]
    param(
        # A session object to BuildMaster. Use the `New-BMSession` function to creates a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the pipeline to get. Supports wildcards.
        [Parameter(ParameterSetName)]
        [String] $Name,

        # The application whose pipelines to get. Passing application ids or objects are supported.
        [Parameter(ParameterSetName)]
        [Object] $Application
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Get-BMRaftItem -Session $session `
                   -Raft $script:defaultRaftId `
                   -Name $Name `
                   -Application $Application `
                   -TypeCode ([BMRaftItemTypeCode]::Pipeline) |
        Add-BMPipelineMember -PassThru
}
