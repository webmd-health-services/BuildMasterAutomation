
function New-BMServerRole
{
    <#
    .SYNOPSIS
    Creates a new server role in a BuildMaster instance.

    .DESCRIPTION
    The `New-BMServerRole` creates a new server role in BuildMaster. Pass the name of the role to the `Name` parameter. Names may only contain letters, numbers, spaces, periods, underscores, or dashes.
    
    Every role must have a unique name. If you create a role with a duplicate name, you'll get an error.
    
    This function uses BuildMaster's infrastructure management API.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use the `New-BMSession` function to create session objects.

    .EXAMPLE
    New-BMServerRole -Session $session -Name 'My Role'

    Demonstrates how to create a new server role.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Za-z0-9 ._-]+$')]
        # The name of the server role to create.
        [string]$Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $encodedName = [uri]::EscapeUriString($Name)
    Invoke-BMRestMethod -Session $Session -Name ('infrastructure/roles/create/{0}' -f $encodedName) -Method Post
}