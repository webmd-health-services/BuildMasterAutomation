
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
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='Basic')]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9_-]*(?<![_-])$')]
        [ValidateLength(1,50)]
        # The name of the server to create. Must contain only letters, numbers, underscores, or dashes. Must begin with a letter. Must not end with an underscore or dash. Must be between 1 and 50 characters long.
        [string]$Name,

        [Parameter(Mandatory)]
        # The type of server to create. Must be one of 'windows', 'powershell', 'ssh', or 'local' (as of this writing). See https://inedo.com/support/documentation/buildmaster/reference/api/infrastructure#data-specification for the most up-to-date list.
        [string]$Type,

        [Parameter(Mandatory,ParameterSetName='AES')]
        # The encryption key to use for the server. When passed, also automatically sets the server's encryption type to AES. Only used by Windows agents.
        [securestring]$EncryptionKey,

        [Parameter(Mandatory,ParameterSetName='Ssl')]
        # Use SSL to communicate with the server's agent. Only used by Windows agents.
        [Switch]$Ssl,

        [Parameter(ParameterSetName='Ssl')]
        # The server's agent only uses SSL. Only used by Windows agents.
        [Switch]$ForceSsl,

        [Parameter(ParameterSetName='SshOrRemoting')]
        [string]$CredentialName,

        [Parameter(ParameterSetName='SshOrRemoting')]
        [string]$TempPath,

        [Parameter(ParameterSetName='SshOrRemoting')]
        [string]$WSManUrl,

        [string[]]$Environment,

        [string[]]$Role,

        # The server's host name. The default is to use the server's name.
        [string]$HostName,

        [uint16]$Port = 46336,

        [hashtable]$Variable,

        [Switch]
        # If set, creates the server but marks it as inactive.
        $Inactive
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $encodedName = [uri]::EscapeUriString($Name)
    $parameter = @{
                    'serverType' = $Type;
                    'active' = (-not $InActive.IsPresent);
                    'hostName' = $Name;
                    'port' = $Port;
                 }
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

    if( $CredentialName )
    {
        $parameter['credentialsName'] = $CredentialName
    }

    if( $TempPath )
    {
        $parameter['tempPath'] = $TempPath
    }

    Invoke-BMRestMethod -Session $Session -Name ('infrastructure/servers/create/{0}' -f $encodedName) -Method Post -Parameter $parameter -AsJson
}