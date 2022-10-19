
function Get-BMRaft
{
    <#
    .SYNOPSIS
    Gets all the rafts from BuildMaster.

    .DESCRIPTION
    The `Get-BMRaft` function returns all rafts from BuildMaster. It uses the native API.

    .EXAMPLE
    Get-BMRaft -Session $session

    Demonstrates how to use `Get-BMRaft` to get all rafts from BuildMaster.
    #>
    [CmdletBinding()]
    param(
        # A session object that represents the BuildMaster instance to use. Use the `New-BMSession` function to create
        # session objects.
        [Parameter(Mandatory)]
        [Object] $Session
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Invoke-BMNativeApiMethod -Session $Session -Name 'Rafts_GetRafts'
}