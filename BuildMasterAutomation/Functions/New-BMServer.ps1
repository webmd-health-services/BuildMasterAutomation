
function New-BMServer
{
    <#
    .SYNOPSIS
    Creates a new server in a BuildMaster instance.

    .DESCRIPTION
    The `New-BMServer` function creates a new server in BuildMaster. Pass the name of the server to the `Name` parameter. Names may only contain letters, numbers, underscores, or dashes; they must begin with a letter; they must not end with dash or underscore. Pass the server type to the `Type` parameter. Type must be one of 'windows', 'powershell', 'ssh', or 'local'.

    Every server must have a unique name. If you creat a server with a duplicate name, you'll get an error.
    
    This function uses BuildMaster's infrastructure management API.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use the `New-BMSession` function to create session objects.

    .LINK
    https://inedo.com/support/documentation/buildmaster/reference/api/infrastructure#data-specification

    .EXAMPLE
    New-BMServer -Session $session -Name 'My Server' -Type 'windows'

    Demonstrates how to create a new server 
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9_-]*(?<![_-])$')]
        [ValidateLength(1,50)]
        # The name of the server to create. Must contain only letters, numbers, underscores, or dashes. Must begin with a letter. Must not end with an underscore or dash. Must be between 1 and 50 characters long.
        [string]$Name,

        [Parameter(Mandatory,ParameterSetName='Local')]
        # Create a local server.
        [Switch]$Local,

        [Parameter(Mandatory,ParameterSetName='Windows')]
        [Parameter(Mandatory,ParameterSetName='WindowsAes')]
        [Parameter(Mandatory,ParameterSetName='WindowsSsl')]
        # Create a Windows server.
        [Switch]$Windows,

        [Parameter(Mandatory,ParameterSetName='Ssh')]
        # Create an SSH server.
        [Switch]$Ssh,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='WindowsAes')]
        [Parameter(ParameterSetName='WindowsSsl')]
        [Parameter(ParameterSetName='Ssh')]
        # The server's host name. The default is to use the server's name.
        [string]$HostName,

        [Parameter(ParameterSetName='Windows')]
        [Parameter(ParameterSetName='WindowsAes')]
        [Parameter(ParameterSetName='WindowsSsl')]
        [Parameter(ParameterSetName='Ssh')]
        # The port to use. When adding a Windows server, the default is `46336`. When adding an SSH server, the default is `22`.
        [uint16]$Port,

        [Parameter(Mandatory,ParameterSetName='WindowsAes')]
        # The encryption key to use for the server. When passed, also automatically sets the server's encryption type to AES. Only used by Windows agents.
        [securestring]$EncryptionKey,

        [Parameter(Mandatory,ParameterSetName='WindowsSsl')]
        # Use SSL to communicate with the server's agent. Only used by Windows agents.
        [Switch]$Ssl,

        [Parameter(ParameterSetName='WindowsSsl')]
        # The server's agent only uses SSL. Only used by Windows agents.
        [Switch]$ForceSsl,

        [Parameter(Mandatory,ParameterSetName='PowerShell')]
        # Create a PowerShell server.
        [Switch]$PowerShell,

        [Parameter(ParameterSetName='PowerShell')]
        # The PowerShell remoting URL to use.
        [string]$WSManUrl,

        [Parameter(ParameterSetName='Ssh')]
        [Parameter(ParameterSetName='PowerShell')]
        # The name of the credential to use when connecting to the server via SSH or PowerShell Remoting.
        [string]$CredentialName,

        [Parameter(ParameterSetName='Ssh')]
        [Parameter(ParameterSetName='PowerShell')]
        # The temp path directory to use when connecting to the server via SSH or PowerShell Remoting. Default is `/tmp/buildmaster`.
        [string]$TempPath,

        [string[]]$Environment,

        [string[]]$Role,

        [hashtable]$Variable,

        [Switch]
        # If set, creates the server but marks it as inactive.
        $Inactive
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $encodedName = [uri]::EscapeUriString($Name)

    $parameter = @{ 
                    'active' = (-not $InActive.IsPresent);
                 }

    if( -not $HostName )
    {
        $HostName = $Name
    }

    if( -not $TempPath )
    {
        $TempPath = '/tmp/buildmaster'
    }

    $serverType = $null
    if( $Windows )
    {
        if( -not $Port )
        {
            $Port = 46336
        }

        $serverType = 'windows'
        $parameter['hostName'] = $HostName
        $parameter['port'] = $Port

        if( $EncryptionKey )
        {
            $parameter['encryptionKey'] = (New-Object 'pscredential' 'encryptionkey',$EncryptionKey).GetNetworkCredential().Password
            $parameter['encryptionType'] = 'aes'
        }

        if( $Ssl )
        {
            $parameter['encryptionType'] = 'ssl'
            $parameter['requireSsl'] = $ForceSsl.IsPresent
        }
    }
    elseif( $Ssh )
    {
        if( -not $Port )
        {
            $Port = 22
        }

        $serverType = 'ssh'
        $parameter['hostName'] = $HostName
        $parameter['port'] = $Port
    }
    elseif( $PowerShell )
    {
        $serverType = 'powershell'

        if( $WSManUrl )
        {
            $parameter['wsManUrl'] = $WSManUrl
        }
    }
    elseif( $Local )
    {
        $serverType = 'local'
    }
    else
    {
        throw 'Don''t know how you got to this code. Well done!'
    }
    $parameter['serverType'] = $serverType;

    if( $Ssh -or $PowerShell )
    {
        if( $CredentialName )
        {
            $parameter['credentialsName'] = $CredentialName
        }

        if( $TempPath )
        {
            $parameter['tempPath'] = $TempPath
        }
    }

    if( $Environment )
    {
        $parameter['environments'] = $Environment
    }

    if( $Role )
    {
        $parameter['roles'] = $Role
    }

    if( $Variable )
    {
        $parameter['variables'] = $Variable
    }

    Invoke-BMRestMethod -Session $Session -Name ('infrastructure/servers/create/{0}' -f $encodedName) -Method Post -Parameter $parameter -AsJson
}