
function Remove-BMRaftItem
{
    <#
    .SYNOPSIS
    Removes a raft item from BuildMaster.

    .DESCRIPTION
    The `Remove-BMRaftItem` function removes a raft item from BuildMaster. Pass the raft item's name or a raft item
    object to the `RaftItem` parameter (or pipe them into the function). The raft item will be deleted, and its change
    history will be preserved.

    To also delete the raft item's change history, use the `PurgeHistory` switch.

    .EXAMPLE
    Remove-BMRaftItem -Session $session -RaftItem 'Tutorial'

    Demonstrates how to delete a raft item using its name.

    .EXAMPLE
    Remove-BMRaftItem -Session $session -RaftItem $raftItem

    Demonstrates how to delete a raft item using a raft item object.

    .EXAMPLE
    $raftItem, 'Tutorial' | Remove-BMRaftItem -Session $session

    Demonstrates that you can pipe raft item names and objects into `Remove-BMRaftItem`.

    .EXAMPLE
    Remove-BMRaftItem -Session $session -RaftItem $raftItem -PurgeHistory

    Demonstrates how to remove the raft item's change history along with the raft item by using the `PurgeHistory`
    switch.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name or or a raft item object of the raft item to delete.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $RaftItem,

        # If set, deletes the raft item's change history. The default behavior preserve's the change history.
        [switch] $PurgeHistory
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $existingRaftItem = $RaftItem | Get-BMRaftItem -Session $Session -Raft $script:defaultRaftId -ErrorAction Ignore
        if (-not $existingRaftItem)
        {
            $appMsg = $RaftItem | Get-BMObjectName -ObjectTypeName 'Application' -ErrorAction Ignore
            if ($appMsg)
            {
                $appMsg = " in application $($appMsg)"
            }
            $msg = "Could not delete raft item ""$($RaftItem | Get-BMObjectName -ObjectTypeName 'RaftItem')""" +
                "$($appMsg) because it does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $raftParams =
            @{} |
            Add-BMObjectParameter -Name 'RaftItem' -Value $RaftItem -ForNativeApi -PassThru |
            Add-BMParameter -Name 'PurgeHistory_Indicator' -Value $PurgeHistory.IsPresent -PassThru

        Invoke-BMNativeApiMethod -Session $Session `
                                -Name 'Rafts_DeleteRaftItem' `
                                -Parameter $raftParams `
                                -Method Post |
            Out-Null
    }
}