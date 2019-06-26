
function Get-BMServerRole
{
    <#
    .SYNOPSIS
    Returns the server roles.

    .DESCRIPTION
    The `Get-BMServerRole` function gets all the server roles from an instance of BuildMaster. By default, this function returns all server roles. To return a specific role, pass its name to the `Name` parameter. The `Name` parameter supports wildcards. If a server role doesn't exist, you'll get an error.

    This function uses BuildMaster's infrastructure management API.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use `New-BMSession` to create a session object.

    .EXAMPLE
    Get-BMServerRole

    Demonstrates how to return a list of all BuildMaster server roles.

    .EXAMPLE
    Get-BMServerRole -Name '*Service*'

    Demonstrates how to use wildcards to search for a service role.
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory,ParameterSetName='Name')]
        # The name of the role to return. Wildcards supported. By default, all roles are returned.
        [string]$Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $roles = $null

    Invoke-BMRestMethod -Session $Session -Name 'infrastructure/roles/list' |
        Where-Object {
            if( $Name )
            {
                $_.name -like $Name
            }
            else
            {
                return $true
            }
        } |
        Tee-Object -Variable 'roles'

    if( $PSCmdlet.ParameterSetName -eq 'All' -or $roles )
    {
        return
    }
    
    if( -not [wildcardpattern]::ContainsWildcardCharacters($Name) )
    {
        Write-Error -Message ('Server role "{0}" does not exist.' -f $Name) -ErrorAction $ErrorActionPreference
    }
}