
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession
$servers = $null

function Init
{
    $Global:Error.Clear()
    Get-BMServer -Session $session | Remove-BMServer -Session $session
    $script:servers = $null
}

function GivenServer
{
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$WithEncryptionKey
    )

    $optionalParams = @{ }
    if( $WithEncryptionKey )
    {
        $optionalParams['EncryptionKey'] = ConvertTo-SecureString -String $WithEncryptionKey -Force -AsPlainText
    }
    New-BMServer -Session $session -Name $Name -Windows @optionalParams
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

function ThenNothingReturned
{
    $servers | Should -BeNullOrEmpty
}

function ThenServersReturned
{
    param(
        [Parameter(Mandatory)]
        [string[]]$Named,

        [string]$WithEncryptionKey
    )

    $servers | Should -HaveCount $Named.Count
    foreach( $name in $Named )
    {
        $servers | Where-Object { $_.Name -eq $name } | Should -Not -BeNullOrEmpty
    }

    if( $WithEncryptionKey )
    {
        foreach( $server in $servers )
        {
            $server.encryptionKey | Should -Not -BeNullOrEmpty
            $credential = New-Object 'pscredential' 'blah',$server.encryptionKey
            $credential.GetNetworkCredential().Password | Should -Be $WithEncryptionKey
            $server.encryptionType | Should -Be 'aes'
        }
    }
}

function WhenGettingServers
{
    [CmdletBinding()]
    param(
        [string]$Named
    )

    $optionalParams = @{ }
    if( $Named )
    {
        $optionalParams['Name'] = $Named
    }
    $script:servers = Get-BMServer -Session $session @optionalParams
    if( $servers )
    {
        $servers | ForEach-Object { $_.pstypenames.Contains( 'Inedo.BuildMaster.Server' ) | Should -BeTrue }
        foreach( $memberName in @( 'name', 'roles', 'environments', 'serverType', 'hostName', 'port', 'encryptionType', 'encryptionKey', 'requireSsl', 'credentialsName', 'tempPath', 'wsManUrl', 'active', 'variables' ) )
        {
            foreach( $server in $servers )
            {
                $server | Get-Member -Name $memberName | Should -Not -BeNullOrEmpty -Because ('member "{0}" should always exist' -f $memberName)
            }
        }
        $keys = $servers | Select-Object -ExpandProperty 'encryptionKey' | Where-Object { $_ } 
        if( $keys )
        {
            $keys | Should -BeOfType ([securestring])
        }
    }
}

Describe 'Get-BMServer.when given no name' {
    It ('should return all servers') {
        Init
        GivenServer 'One'
        GivenServer 'Two'
        WhenGettingServers
        ThenServersReturned 'One','Two'
        ThenNoErrorWritten
    }
}

Describe 'Get-BMServer.when server has an encryption key' {
    It ('should convert encryption key to a securestring') {
        Init
        GivenServer 'One' -WithEncryptionKey '9c59b9ee17824c79a953636416c697ed'
        WhenGettingServers
        ThenServersReturned 'One' -WithEncryptionKey '9c59b9ee17824c79a953636416c697ed'
        ThenNoErrorWritten
    }
}

Describe 'Get-BMServer.when given name' {
    It ('should return named server') {
        Init
        GivenServer 'One'
        GivenServer 'Two'
        WhenGettingServers -Named 'One'
        ThenServersReturned 'One'
    }
}

Describe 'Get-BMServer.when given wildcards' {
    It ('should return only server whose name match the wildcard') {
        Init
        GivenServer 'One'
        GivenServer 'Onf'
        GivenServer 'Two'
        WhenGettingServers -Named 'On*'
        ThenServersReturned 'One','Onf'
    }
}

Describe 'Get-BMServer.when given wildcard that matches no servers' {
    It ('should return nothing and write no errors') {
        Init
        GivenServer 'One'
        WhenGettingServers -Named 'Blah*'
        ThenNothingReturned
        ThenNoErrorWritten
    }
}

Describe 'Get-BMServer.when given name for a server that doesn''t exist' {
    It ('should return nothing and write an error') {
        Init
        GivenServer 'One'
        WhenGettingServers -Named 'Blah' -ErrorAction SilentlyContinue
        ThenNothingReturned
        ThenError 'does\ not\ exist'
    }
}

Describe 'Get-BMServer.when ignoring when a server doesn''t exist' {
    It ('should return nothing and write an error') {
        Init
        GivenServer 'One'
        WhenGettingServers -Named 'Blah' -ErrorAction Ignore
        ThenNothingReturned
        ThenNoErrorWritten
    }
}
