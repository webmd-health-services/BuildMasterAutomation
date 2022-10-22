
function Remove-BMPipeline
{
    <#
    .SYNOPSIS
    Removes a pipeline from BuildMaster.

    .DESCRIPTION
    The `Remove-BMPipeline` function removes a pipeline from BuildMaster. Pass the pipeline's name or object to the
    `Pipeline` parameter (or pipe it into the function). The pipeline will be deleted, and its change history will be
    preserved.

    To also delete the pipeline's change history, use the `PurgeHistory` switch.

    .EXAMPLE
    Remove-BMPipeline -Session $session -Pipeline 'Tutorial'

    Demonstrates how to delete a pipeline using its name.

    .EXAMPLE
    Remove-BMPipeline -Session $session -Pipeline $pipeline

    Demonstrates how to delete a pipeline using a pipeline object.

    .EXAMPLE
    $pipeline, 'Tutorial' | Remove-BMPipeline -Session $session

    Demonstrates that you can pipe pipeline names and objects into `Remove-BMPipeline`.

    .EXAMPLE
    Remove-BMPipeline -Session $session -Pipeline $pipeline -PurgeHistory

    Demonstrates how to remove the pipeline's change history along with the pipeline by using the `PurgeHistory` switch.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name or pipeline object of the pipeline to delete.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Pipeline,

        # If set, deletes the pipeline's change history. The default behavior preserve's the change history.
        [switch] $PurgeHistory
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $Pipeline | Remove-BMRaftItem -Session $session -PurgeHistory:$PurgeHistory
    }
}