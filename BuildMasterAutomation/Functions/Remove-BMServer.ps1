
function Remove-BMServer
{
    <#
    .SYNOPSIS
    Removes a server from BuildMaster.

    .DESCRIPTION
    The `Remove-BMServer` function removes a server from BuildMaster. Pass the name of the server to remove to the `Name` parameter. If the server doesn't exist, nothing happens.

    Pass the session to the BuildMaster instance where you want to delete the server to the `Session` parameter. Use `New-BMSession` to create a session object.

    This function uses BuildMaster's infrastructure management API.

    .EXAMPLE
    Remove-BMServer -Session $session -Name 'example.com'

    Demonstrates how to delete a server.

    .EXAMPLE
    Get-BMServer -Session $session -Name 'example.com' | Remove-BMServer -Session $session

    Demonstrates that you can pipe the objects returned by `Get-BMServer` into `Remove-BMServer` to remove those servers.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        # The instance of BuildMaster to connect to.
        [object]$Session,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        # The name of the server to remove.
        [string]$Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $encodedName = [uri]::EscapeDataString($Name)
        Invoke-BMRestMethod -Session $Session -Name ('infrastructure/servers/delete/{0}' -f $encodedName) -Method Delete
    }
}