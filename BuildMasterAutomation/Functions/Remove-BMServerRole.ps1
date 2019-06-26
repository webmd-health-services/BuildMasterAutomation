
function Remove-BMServerRole
{
    <#
    .SYNOPSIS
    Removes a server role from BuildMaster.

    .DESCRIPTION
    The `Remove-BMServerRole` removes a server role from BuildMaster. Pass the name of the role to remove to the `Name` parameter. If the server role doesn't exist, nothing happens.

    Pass the session to the BuildMaster instance where you want to delete the role to the `Session` parameter. Use `New-BMSession` to create a session object.

    This function uses BuildMaster's infrastructure management API.

    .EXAMPLE
    Remove-BMServerRole -Session $session -Name 'Server Role'

    Demonstrates how to delete a server role.

    .EXAMPLE
    Get-BMServerRole -Session $session -Name 'My Role' | Remove-BMServerRole -Session $session

    Demonstrates that you can pipe the objects returned by `Get-BMServerRole` into `Remove-BMServerRole` to remove those roles.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        # The name of the role to remove.
        [string]$Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $encodedName = [uri]::EscapeUriString($Name)
        Invoke-BMRestMethod -Session $Session -Name ('infrastructure/roles/delete/{0}' -f $encodedName) -Method Delete
    }
}