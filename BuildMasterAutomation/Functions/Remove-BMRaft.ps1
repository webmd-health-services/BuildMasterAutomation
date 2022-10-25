
function Remove-BMRaft
{
    <#
    .SYNOPSIS
    Removes rafts from BuildMaster.

    .DESCRIPTION
    The `Remove-BMRaft` function removes a raft from BuildMaster. Pass its id, name, or raft object to the `Raft`
    parameter (or pipe to the function). If the raft exists, it is deleted. If it doesn't exist, an error is written.

    Uses BuildMaster's native API.

    .EXAMPLE
    Get-BMRaft -Session $session -Name 'delete me' | Remove-BMRaft -Session $Session

    Demonstrates how to delete a raft by using a raft object.

    .EXAMPLE
    'delete me' | Remove-BMRaft -Session $Session

    Demonstrates how to delete a raft by using the raft's name.

    .EXAMPLE
    134 | Remove-BMRaft -Session $Session

    Demonstrates how to delete a raft by using its id.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The raft id, name, or raft object to delete.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Raft
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $raftId = $Raft | Get-BMObjectID -ObjectTypeName 'Raft' -ErrorAction Ignore
        $raftName = $Raft | Get-BMObjectName -ObjectTypeName 'Raft' -ErrorAction Ignore
        $bmRaft =
            Get-BMRaft -Session $Session |
            Where-Object {
                if ($null -ne $raftId -and $_.Raft_Id -eq $raftId)
                {
                    return $true
                }

                if ($null -ne $raftName -and $_.Raft_Name -eq $raftName)
                {
                    return $true
                }

                return $false
            }

        if (-not $bmRaft)
        {
            $msg = "Unable to delete raft ""$($Raft | Get-BMObjectName)"" because it does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $parameter = @{ 'Raft_Id' = $bmRaft.Raft_Id }
        Invoke-BMNativeApiMethod -Session $Session -Name 'Rafts_DeleteRaft' -Method Post -Parameter $parameter
    }
}