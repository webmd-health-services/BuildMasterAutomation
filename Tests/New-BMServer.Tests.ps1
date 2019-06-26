
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
}

function GivenServer
{
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Parameter(Mandatory)]
        [string]$WithType
    )

    New-BMServer -Session $session -Name $Named -Type $WithType
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
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Parameter(Mandatory)]
        [string]$OfType,

        [string]$WithEncryptionKey,

        [Switch]$Ssl,

        [Switch]$ForceSsl,

        [string]$CredentialName,

        [string]$TempPath
    )

    $server = Get-BMServer -Session $session -Name $Named 
    $server | Should -Not -BeNullOrEmpty
    $server.serverType | Should -Be $OfType
    $server.port | Should -Be 46336
    $server.hostName | Should -Be $Named
    
    if( $WithEncryptionKey )
    {
        $server.encryptionType | Should -Be 'aes'
        $keyAsCred = New-Object 'pscredential' 'encryptionkey',$server.encryptionKey
        $keyAsCred.GetNetworkCredential().Password | Should -Be $WithEncryptionKey
    }
    
    if( $Ssl )
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

    if( $CredentialName )
    {
        $server.credentialsName | Should -Be $CredentialName
    }
    else
    {
        $server.credentialsName | Should -BeNullOrEmpty
    }

    if( $TempPath )
    {
        $server.tempPath | Should -Be $TempPath
    }
    else
    {
        $server.tempPath | Should -BeNullOrEmpty
    }
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

        [AllowNull()]
        [string]$CredentialName,

        [AllowNull()]
        [string]$TempPath,

        [Switch]
        $WhatIf
    )

    $optionalParams = @{ }
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

    $script:result = New-BMServer -Session $session -Name $Named -Type $OfType @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'New-BMServer' {
    It ('should create server') {
        Init
        WhenCreatingServer -Named 'Fubar' -OfType 'windows'
        ThenNoErrorWritten
        ThenServerExists -Named 'Fubar' -OfType 'windows'
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
        ThenServerExists -Named $name -OfType 'windows'
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
        ThenServerExists -Named 'One' -OfType 'windows' -WithEncryptionKey '4F8F4BAC0E664780B63AF3350EB98551'
    }
}

Describe 'New-BMServer.when creating server that uses SSL encryption' {
    It ('should create the server with its encryption key') -Skip {
        Init
        WhenCreatingServer -Named 'One' -OfType 'windows' -Ssl
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'windows' -Ssl
    }
}

Describe 'New-BMServer.when creating server that requires SSL encryption' {
    It ('should create the server with its encryption key') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'windows' -Ssl -ForceSsl
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'windows' -Ssl -ForceSsl
    }
}

Describe 'New-BMServer.when configuring an SSH agent' {
    It ('should create the server with its encryption key') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'ssh'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'ssh' -TempPath '/tmp/buildmaster'
    }
}

Describe 'New-BMServer.when configuring an SSH agent' {
    It ('should create the server with its encryption key') {
        Init
        WhenCreatingServer -Named 'One' -OfType 'ssh' -CredentialName 'blahblah' -TempPath '/var/inedo/buildmaster/temp'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'ssh' -CredentialName 'blahblah' -TempPath '/var/inedo/buildmaster/temp'
    }
}