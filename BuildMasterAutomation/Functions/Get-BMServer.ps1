
function Get-BMServer
{
    <#
    .SYNOPSIS
    Returns servers in BuildMaster.

    .DESCRIPTION
    The `Get-BMServer` function gets all the servers from an instance of BuildMaster. To return a specific server,
    pipe the server's id, name (wildcards supported), or a server object to the function (or pass to the `Server`
    parameter). If the server doesn't exist, the function writes an error.

    The BuildMaster API returns plaintext versions of a server's API key (if it is using AES encryption). This function
    converts those keys into `SecureString` objects to make it harder to accidentally view/save them.

    This function uses BuildMaster's infrastructure management API.

    .EXAMPLE
    Get-BMServer

    Demonstrates how to return a list of all BuildMaster servers.

    .EXAMPLE
    '*example*' | Get-BMServer

    Demonstrates how to use wildcards to search for a server.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object]$Session,

        # The name of the server to return. Wildcards supported. By default, all servers are returned.
        [Parameter(ValueFromPipeline)]
        [Alias('Name')]
        [Object] $Server
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false

        $servers = $null

        $serverName = $Server | Get-BMObjectName -Strict -ErrorAction Ignore
        $searching = $serverName -and [wildcardpattern]::ContainsWildcardCharacters($serverName)

        # BuildMaster API doesn't always return all a server's members.
        $memberNames = @(
            'name',
            'roles',
            'environments',
            'serverType',
            'hostName',
            'port',
            'encryptionType',
            'encryptionKey',
            'requireSsl',
            'credentialsName',
            'tempPath',
            'wsManUrl',
            'active',
            'variables'
        )

        Invoke-BMRestMethod -Session $Session -Name 'infrastructure/servers/list' |
            Where-Object {
                if ($serverName)
                {
                    return ($_.name -like $serverName)
                }
                return $true
            } |
            Add-PSTypeName -Server |
            ForEach-Object {
                $server = $_
                foreach ($memberName in $memberNames)
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
            Tee-Object -Variable 'servers' |
            Write-Output

        if (-not $searching -and $Server -and -not $servers)
        {
            $msg = "Server ""$($Server | Get-BMObjectName)"" does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}