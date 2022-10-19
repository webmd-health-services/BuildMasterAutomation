
function Get-BMServer
{
    <#
    .SYNOPSIS
    Returns servers in BuildMaster.

    .DESCRIPTION
    The `Get-BMServer` function gets all the servers from an instance of BuildMaster. By default, this function returns all servers. To return a specific server, pass its name to the `Name` parameter.  If a server with that name doesn't exist, you'll get an error. The `Name` parameter supports wildcards. If you search with wildcards and a server doesn't exist, you won't get any errors.

    The BuildMaster API returns plaintext versions of a server's API key (if it is using AES encryption). This function converts those keys into `SecureString`s to make it harder to accidentally view/save them.

    This function uses BuildMaster's infrastructure management API.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use `New-BMSession` to create a session object.

    .EXAMPLE
    Get-BMServer

    Demonstrates how to return a list of all BuildMaster servers.

    .EXAMPLE
    Get-BMServer -Name '*example*'

    Demonstrates how to use wildcards to search for a server.
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory,ParameterSetName='Name')]
        # The name of the server to return. Wildcards supported. By default, all servers are returned.
        [string]$Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $WhatIfPreference = $false

    $servers = $null

    Invoke-BMRestMethod -Session $Session -Name 'infrastructure/servers/list' |
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
        Add-PSTypeName -Server |
        ForEach-Object {
            $server = $_
            foreach( $memberName in @( 'name', 'roles', 'environments', 'serverType', 'hostName', 'port', 'encryptionType', 'encryptionKey', 'requireSsl', 'credentialsName', 'tempPath', 'wsManUrl', 'active', 'variables' ) )
            {
                if( -not ($server | Get-Member -Name $memberName) )
                {
                    $server | Add-Member -MemberType NoteProperty -Name $memberName -Value $null
                }
            }

            if( $server.encryptionKey )
            {
                $server.encryptionKey = ConvertTo-SecureString -String $_.encryptionKey -AsPlainText -Force
            }
            $server
        } |
        Tee-Object -Variable 'servers'

    if( $PSCmdlet.ParameterSetName -eq 'All' -or $servers )
    {
        return
    }

    if( -not [wildcardpattern]::ContainsWildcardCharacters($Name) )
    {
        Write-Error -Message ('Server "{0}" does not exist.' -f $Name) -ErrorAction $ErrorActionPreference
    }
}