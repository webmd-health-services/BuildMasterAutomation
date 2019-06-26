
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession
$result = $null

function Init
{
    $Global:Error.Clear()
    $script:result = $null
    Get-BMServer -Session $session | Remove-BMServer -Session $session
    Get-BMServerRole -Session $session | Remove-BMServerRole -Session $session
    Invoke-BMRestMethod -Session $session -Name 'infrastructure/environments/list' |
        ForEach-Object { 
            Invoke-BMRestMethod -Session $session -Name ('infrastructure/environments/delete/{0}' -f ([uri]::EscapeDataString($_.name))) -Method Delete }
}

function GivenEnvironment
{
    param(
        [Parameter(Mandatory)]
        [string[]]$Named
    )

    # Environments can't actually be deleted. They can only be disabled. So, we have to re-enable any environments that were deactivated.
    $environments = Invoke-BMNativeApiMethod -Session $session -Name 'Environments_GetEnvironments' -Parameter @{ IncludeInactive_Indicator = $true } -Method Post
    foreach( $name in $Named )
    {
        $environment = $environments | Where-Object { $_.Environment_Name -eq $name }
        if( $environment )
        {
            if( -not $environment.Active_Indicator )
            {
                Invoke-BMNativeApiMethod -Session $session -Name 'Environments_UndeleteEnvironment' -Parameter @{ 'Environment_Id' = $environment.environment_Id } -Method Post
            }
        }
        else
        {
            Invoke-BMRestMethod -Session $session -Name ('infrastructure/environments/create/{0}' -f ([uri]::EscapeDataString($name))) -Method Post -Body ('{{ "name": "{0}" }}' -f $name)
        }
    }
}

function GivenServer
{
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Parameter(Mandatory)]
        [ValidateSet('windows','ssh','powershell','local')]
        [string]$WithType
    )

    if( $WithType -eq 'windows' )
    {
        # PowerShell can't find this parameter set if you splat the Windows switch. Weird.
        New-BMServer -Session $session -Name $Named -Windows
    }
    else
    {
        New-BMServer -Session $session -Name $Named @{ $WithType = $true }
    }
}

function GivenServerRole
{
    param(
        [Parameter(Mandatory)]
        [string[]]$Named
    )

    foreach( $name in $Named )
    {
        New-BMServerRole -Session $session -Name $name
    }
}

function ThenError
{
    param(
        [Parameter(Mandatory)]
        [string]$Matches
    )

    $Global:Error | Should -Match $Matches
}

function ThenNoErrorWritten
{
    $Global:Error | Should -BeNullOrEmpty
}

function ThenServerExists
{
    [CmdletBinding(DefaultParameterSetName='AnyType')]
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Parameter(Mandatory)]
        [string]$OfType,

        [Parameter(ParameterSetName='Windows')]
        [string]$WithEncryptionKey,

        [Parameter(ParameterSetName='Windows')]
        [Switch]$Ssl,

        [Parameter(ParameterSetName='Windows')]
        [Switch]$ForceSsl,

        [string]$CredentialName,

        [string]$TempPath,

        [string]$WSManUrl,

        [object]$Port,

        [object]$HostName,

        [string[]]$Environment,

        [string[]]$Role,

        [hashtable]$Variable
    )

    function Assert-Property
    {
        param(
            [Parameter(Mandatory,Position=0)]
            [string[]]$Name,

            [Parameter(Mandatory,ParameterSetName='ShouldBeOrNull')]
            [AllowNull()]
            [object]$ShouldBeOrNull,

            [Parameter(Mandatory,ParameterSetName='ShouldBeNullOrEmpty')]
            [Switch]$ShouldBeNullOrEmpty
        )

        foreach( $propertyName in $Name )
        {
            if( $ShouldBeOrNull )
            {
                $actualValue = $server.$propertyName
                if( $ShouldBeOrNull -is [hashtable] )
                {
                    $actualValue | Get-Member -MemberType NoteProperty | Should -HaveCount $ShouldBeOrNull.Count
                    foreach( $key in $ShouldBeOrNull.Keys )
                    {
                        $actualValue.$key | Should -Be $ShouldBeOrNull[$key]
                    }
                }
                else
                {
                    $actualValue | Should -Be $ShouldBeOrNull
                }
            }
            else
            {
                $server.$propertyName | Should -BeNullOrEmpty
            }
        }
    }

    $server = Get-BMServer -Session $session -Name $Named

    $server | Should -Not -BeNullOrEmpty
    $server.serverType | Should -Be $OfType
    $server.name | Should -Be $Named

    if( -not $HostName )
    {
        $HostName = $Named
    }

    if( -not $TempPath )
    {
        $TempPath = '/tmp/buildmaster'
    }

    if( $OfType -eq 'windows' )
    {
        if( -not $Port )
        {
            $Port = 46336
        }
        $server.port | Should -Be $Port
        $server.hostName | Should -Be $HostName
        if( $WithEncryptionKey )
        {
            $server.encryptionType | Should -Be 'aes'
            $keyAsCred = New-Object 'pscredential' 'encryptionkey',$server.encryptionKey
            $keyAsCred.GetNetworkCredential().Password | Should -Be $WithEncryptionKey
            $server.requireSsl | Should -Be $null
        }
        elseif( $Ssl )
        {
            $server.encryptionType | Should -Be 'ssl'
            if( $ForceSsl )
            {
                $server.requireSsl | Should -BeTrue
            }
            else
            {
                $server.requireSsl | Should -BeFalse
            }
        }
        else
        {
            $server.encryptionType = 'none'
        }
        Assert-Property 'credentialsName','tempPath','wsManUrl' -ShouldBeNullOrEmpty
    }
    elseif( $OfType -eq 'ssh' )
    {
        if( -not $Port )
        {
            $Port = 22
        }
        $server.hostName | Should -Be $HostName
        $server.port | Should -Be $Port
        Assert-Property 'credentialsName' -ShouldBeOrNull $CredentialName
        Assert-Property 'tempPath' -ShouldBeOrNull $TempPath
        Assert-Property 'encryptionType','encryptionKey','requireSsl' -ShouldBeNullOrEmpty
    }
    elseif( $OfType -eq 'powershell' )
    {
        Assert-Property 'credentialsName' -ShouldBeOrNull $CredentialName
        Assert-Property 'tempPath' -ShouldBeOrNull $TempPath
        Assert-Property 'wsManUrl' -ShouldBeOrNull $WSManUrl
        Assert-Property 'hostName','port','encryptionType','encryptionKey','requireSsl' -ShouldBeNullOrEmpty
    }
    elseif( $OfType -eq 'local' )
    {
        Assert-Property 'hostName','port','encryptionType','encryptionKey','requireSsl','credentialsName','tempPath','wsManUrl' -ShouldBeNullOrEmpty
    }

    Assert-Property 'environments' -ShouldBeOrNull $Environment
    Assert-Property 'roles' -ShouldBeOrNull $Role
    Assert-Property 'variables' -ShouldBeOrNull $Variable
}

function ThenServerDoesNotExist
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    Get-BMServer -Session $session -Name $Named -ErrorAction Ignore | Should -BeNullOrEmpty
}

function WhenCreatingServer
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Parameter(Mandatory)]
        [string]$OfType,

        [string]$WithEncryptionKey,

        [Switch]$Ssl,

        [Switch]$ForceSsl,

        [string]$CredentialName,

        [string]$TempPath,

        [string]$WSManUrl,

        [Switch]$WhatIf,

        [uint16]$Port,
        
        [string]$HostName,

        [string[]]$InEnvironments,

        [string[]]$AsRoles,

        [hashtable]$WithVariables
    )

    $optionalParams = @{
                            $OfType = $true;
                      }
    if( $WhatIf )
    {
        $optionalParams['WhatIf'] = $true
    }

    if( $WithEncryptionKey )
    {
        $optionalParams['EncryptionKey'] = ConvertTo-SecureString -String $WithEncryptionKey -AsPlainText -Force
    }

    if( $Ssl )
    {
        $optionalParams['Ssl'] = $true
    }

    if( $ForceSsl )
    {
        $optionalParams['ForceSsl'] = $true
    }
    
    if( $CredentialName )
    {
        $optionalParams['CredentialName'] = $CredentialName
    }

    if( $TempPath )
    {
        $optionalParams['TempPath'] = $TempPath
    }

    if( $WSManUrl )
    {
        $optionalParams['WSManUrl'] = $WSManUrl
    }

    if( $Port )
    {
        $optionalParams['Port'] = $Port
    }

    if( $HostName )
    {
        $optionalParams['HostName'] = $HostName
    }

    if( $InEnvironments )
    {
        $optionalParams['Environment'] = $InEnvironments
    }

    if( $AsRoles )
    {
        $optionalParams['Role'] = $AsRoles
    }

    if( $WithVariables )
    {
        $optionalParams['Variable'] = $WithVariables
    }

    $script:result = New-BMServer -Session $session -Name $Named @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'New-BMServer.when creating basic windows server' {
    It ('should create server') {
        Init
        WhenCreatingServer -Named 'Fubar' -OfType 'windows'
        ThenNoErrorWritten
        ThenServerExists -Named 'Fubar' -OfType 'windows'
    }
}

Describe 'New-BMServer.when creating local server' {
    It ('should create server') {
        Init
        WhenCreatingServer -Named 'Fubar' -OfType 'local'
        ThenNoErrorWritten
        ThenServerExists -Named 'Fubar' -OfType 'local'
    }
}

foreach( $badChar in @( '_', '-' ) )
{
    Describe ('New-BMServer.when name ends with "{0}"' -f $badChar) {
        It ('should not create server') {
            $name = 'Fubar{0}' -f $badChar
            Init
            { WhenCreatingServer -Named $name -OfType 'windows' } | Should -Throw
            ThenError 'does\ not\ match'
            ThenServerDoesNotExist -Named $name
        }
    }
    
}

Describe ('New-BMServer.when name contains characters that it shouldn''t end with') {
    It ('should create server') {
        $name = 'Fubar_-Snafu'
        Init
        WhenCreatingServer -Named $name -OfType 'windows'
        ThenNoErrorWritten
        ThenServerExists -Named $name -OfType 'windows'
    }
}

Describe ('New-BMServer.when name contains one letter') {
    It ('should create server') {
        $name = 'F'
        Init
        WhenCreatingServer -Named $name -OfType 'windows'
        ThenNoErrorWritten
        ThenServerExists -Named $name -OfType 'windows' -HostName $name
    }
}

Describe ('New-BMServer.when name is too long') {
    It ('should not create server') {
        $name = 'F' * 51
        Init
        { WhenCreatingServer -Named $name -OfType 'windows' } | Should -Throw
        ThenError 'is\ too\ long'
        ThenServerDoesNotExist -Named $name
    }
}

Describe 'New-BMServer.when server already exists' {
    It ('should write an error') {
        Init
        GivenServer -Named 'One' -WithType 'windows'
        WhenCreatingServer -Named 'One' -OfType 'windows' -ErrorAction SilentlyContinue 
        ThenError 'already\ exists'
    }
}

Describe 'New-BMServer.when ignoring when a server already exists' {
    It ('should not write any errors or return anything') {
        Init
        GivenServer -Named 'One' -WithType 'windows'
        WhenCreatingServer -Named 'One' -OfType 'windows' -ErrorAction Ignore
        ThenNoErrorWritten
    }
}

Describe 'New-BMServer.when using -WhatIf' {
    It ('should not create the server') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'windows' -WhatIf
        ThenNoErrorWritten
        ThenServerDoesNotExist -Named 'One'
    }
}

Describe 'New-BMServer.when creating server that uses AES encryption' {
    It ('should create the server with its encryption key') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'windows' -WithEncryptionKey '4F8F4BAC0E664780B63AF3350EB98551'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'windows' -WithEncryptionKey '4F8F4BAC0E664780B63AF3350EB98551' -HostName 'One'
    }
}

Describe 'New-BMServer.when creating server that uses SSL encryption' {
    It ('should create the server with its encryption key') -Skip {
        Init
        WhenCreatingServer -Named 'One' -OfType 'windows' -Ssl
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'windows' -Ssl -HostName 'One'
    }
}

Describe 'New-BMServer.when creating server that requires SSL encryption' {
    It ('should create the server with its encryption key') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'windows' -Ssl -ForceSsl
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'windows' -Ssl -ForceSsl -HostName 'One'
    }
}

Describe 'New-BMServer.when configuring an SSH agent' {
    It ('should create the server') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'ssh'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'ssh'
    }
}

Describe 'New-BMServer.when configuring an SSH agent and customizing properties' {
    It ('should create the server') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'ssh' -CredentialName 'blahblah' -TempPath '/var/inedo/buildmaster/temp' -Port 7999 -HostName 'one.example.com'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'ssh' -CredentialName 'blahblah' -TempPath '/var/inedo/buildmaster/temp' -HostName 'one.example.com' -Port 7999
    }
}

Describe 'New-BMServer.when configuring powershell agent' {
    It ('should create the server') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'powershell'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'powershell'
    }
}

Describe 'New-BMServer.when configuring powershell agent and customizing settings' {
    It ('should create the server') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'powershell' -CredentialName 'blahblah' -TempPath '/var/inedo/buildmaster/temp' -WSManUrl 'http://example.com'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'powershell' -CredentialName 'blahblah' -TempPath '/var/inedo/buildmaster/temp' -WSManUrl 'http://example.com'
    }
}

Describe 'New-BMServer.when setting roles, environments, and variables' {
    It ('should create the server') {
        $variables = @{ 'one' = 'a'; 'two' = 'three'; 'four' = 'five'; }
        Init
        GivenEnvironment 'one','two'
        GivenServerRole 'role1','role2'
        WhenCreatingServer -Named 'rev' -OfType 'local' -InEnvironment 'one','two' -AsRoles 'role1','role2' -WithVariables $variables
        ThenNoErrorWritten
        ThenServerExists -Named 'rev' -OfType 'local' -Environment 'one','two' -Role 'role1','role2' -Variable $variables
    }
}