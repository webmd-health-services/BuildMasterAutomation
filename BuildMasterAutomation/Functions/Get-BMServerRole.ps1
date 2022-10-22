
function Get-BMServerRole
{
    <#
    .SYNOPSIS
    Returns the server roles.

    .DESCRIPTION
    The `Get-BMServerRole` function gets all the server roles from an instance of BuildMaster. To return a specific
    role, pipe a server role id, name (wildcards supported), or a server role object to the function (or pass to the
    `ServerRole` parameter). If the server isn't found, the function write an error.

    This function uses BuildMaster's infrastructure management API.

    .EXAMPLE
    Get-BMServerRole

    Demonstrates how to return a list of all BuildMaster server roles.

    .EXAMPLE
    '*Service*' | Get-BMServerRole

    Demonstrates how to use wildcards to search for a service role.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. New `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The server role to return. Pass a server role id, name (wildcards supported), or server role object.
        [Parameter(ValueFromPipeline)]
        [Object] $ServerRole
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $roles = $null
        $serverRoleName = $ServerRole | Get-BMObjectName -Strict -ErrorAction Ignore
        $searching = $serverRoleName -and [wildcardpattern]::ContainsWildcardCharacters($serverRoleName)

        Invoke-BMRestMethod -Session $Session -Name 'infrastructure/roles/list' |
            Where-Object {
                if ($serverRoleName)
                {
                    return ($_.name -like $serverRoleName)
                }
                return $true
            } |
            Tee-Object -Variable 'roles' |
            Write-Output

        if (-not $searching -and $ServerRole -and -not $roles)
        {
            $msg = "Server role ""$($ServerRole | Get-BMObjectName)"" does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}