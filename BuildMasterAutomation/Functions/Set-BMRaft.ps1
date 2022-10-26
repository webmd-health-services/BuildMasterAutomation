
function Set-BMRaft
{
    <#
    .SYNOPSIS
    Creates and updates rafts in BuildMaster.

    .DESCRIPTION
    The `Set-BMRaft` function creates and updates rafts in BuildMaster. To create a raft, pass its name to the `Raft`
    parameter (or pipe the name to `Set-BMRaft`), its optional XML configuration to the `Configuration` parameter, and
    the raft's environment id, name, or environment object to the `Environment` parameter.

    To update a raft, pass its name, id, or raft object to the `Raft` parameter, and any new/changed values passed to
    the `Configuration` and `Environment` parameter.

    If you want the newly created or updated raft to be returned, use the `PassThru` switch.

    Uses the BuildMaster native API.

    .EXAMPLE
    'New Raft' | Set-Raft -Session $session

    Demonstrates how to create a new Raft by piping its name to the `Set-BMRaft` function.

    .EXAMPLE
    Get-BMRaft -Name 'Update Me!' | Set-Raft -Session $session -Configuration $newConfig -Environment $newEnv

    Demonstrates how to update an existing raft by piping the raft object to `Set-Raft`, new configuration to the
    `Configuration` parameter, and new environment to the `Environment` parameter.

    .EXAMPLE
    $bmRaft = 'New Or Updated Raft' | Set-Raft -Session $session -PassThru

    Demonstrates how to get a raft object for the new or updated raft by using the `PassThru` switch.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The raft's name, id, or raft object. When creating a raft, this *must* be the new raft's name.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Raft,

        # The XML configuration for the raft.
        [String] $Configuration,

        # The environment id, name, or environment object the raft should belong to.
        [Object] $Environment,

        # If set, the new/updated raft will be returned.
        [switch] $PassThru
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $bmEnv = $null
        if( $Environment )
        {
            $bmEnv = $Environment | Get-BMEnvironment -Session $Session -ErrorAction Ignore
            if (-not $bmEnv)
            {
                $msg = "Unable to set raft ""$($Raft | Get-BMObjectName)"" because the environment " +
                    """$($bmEnv | Get-BMObjectName)"" does not exist."
                Write-Error -Message $msg
                return
            }
        }

        $raftID = $Raft | Get-BMObjectID -ObjectTypeName 'Raft' -ErrorAction Ignore
        $raftName = $Raft | Get-BMObjectName -ObjectTypeName 'Raft' -ErrorAction Ignore
        $bmRaft = Get-BMRaft -Session $Session | Where-Object {
            if ($null -ne $raftID -and ($_.Raft_Id -eq $raftID))
            {
                return $true
            }

            if ($null -ne $raftName -and $_.Raft_Name -eq $raftName)
            {
                return $true
            }

            return $false
        }

        if ($bmRaft -and $null -eq $raftName)
        {
            $raftName = $bmRaft.Raft_Name
        }

        $parameters =
            @{} |
            Add-BMObjectParameter -Name 'Raft' -Value $bmRaft -AsID -ForNativeApi -PassThru | `
            Add-BMObjectParameter -Name 'Raft' -Value $raftName -AsName -ForNativeApi -PassThru | `
            Add-BMParameter -Name 'Raft_Configuration' -Value $PSBoundParameters['Configuration'] -PassThru | `
            Add-BMObjectParameter -Name 'Environment' -Value $bmEnv -AsId -ForNativeApi -PassThru

        $id = Invoke-BMNativeApiMethod -Session $Session `
                                       -Name 'Rafts_CreateOrUpdateRaft' `
                                       -Method Post `
                                       -Parameter $parameters

        if ($PassThru)
        {
            return Get-BMRaft -Session $Session | Where-Object 'Raft_Id' -EQ $id
        }

    }
}