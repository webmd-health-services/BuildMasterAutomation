
function Get-BMRaft
{
    <#
    .SYNOPSIS
    Gets rafts from BuildMaster.

    .DESCRIPTION
    The `Get-BMRaft` function returns all rafts from BuildMaster.

    To get a specific raft, pass its name, id, or raft object to the `Raft` parameter (or pipe them into the function).
    If a raft with the given ID or represented by the object doesn't exist, the function writes an error and returns.
    If a string is passed to the `Raft` parameter, and it contains wildcards, the function will return all rafts whose
    names match the wildcard pattern. Otherwise, it will return the raft with that name and if it doesn't find a raft
    with that name, it writes an error and returns nothing.

    This function uses the native API.

    .EXAMPLE
    Get-BMRaft -Session $session

    Demonstrates how to use `Get-BMRaft` to get all rafts.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use the `New-BMSession` function to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The raft id, name, or raft object to get. If you pass a string, and the string has wildcards, all rafts whose
        # name matches the wildcard pattern are returned.
        [Parameter(ValueFromPipeline)]
        [Object] $Raft
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false  # We only get stuff in this function.

        $searching = ($Raft | Test-BMName) -and [wildcardpattern]::ContainsWildcardCharacters($Raft)
        $raftName = $Raft | Get-BMObjectName -ObjectTypeName 'Raft' -ErrorAction Ignore

        $endpointName = 'Rafts_GetRaft'
        if ($searching -or -not $Raft)
        {
            $endpointName = 'Rafts_GetRafts'
        }

        $parameters = @{}
        if ($endpointName -eq 'Rafts_GetRaft')
        {
            $raftID = $Raft | Get-BMObjectID -ObjectTypeName 'Raft' -ErrorAction Ignore
            if ($raftID)
            {
                $parameters['Raft_Id'] = $raftID
            }
            elseif ($raftName)
            {
                $parameters['Raft_Name'] = $raftName
            }
        }

        $rafts = @()
        Invoke-BMNativeApiMethod -Session $Session -Name $endpointName -Method Post -Parameter $parameters |
            Where-Object {
                if ($searching)
                {
                    return $_.Raft_Name -like $raftName
                }

                return $true
            } |
            Tee-Object -Variable 'rafts' |
            Write-Output

        if ($Raft -and -not $rafts -and -not $searching)
        {
            $msg = "Raft ""$($Raft | Get-BMObjectName)"" does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}