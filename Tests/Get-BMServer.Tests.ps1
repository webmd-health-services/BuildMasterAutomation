
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:servers = $null

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
        New-BMServer -Session $script:session -Name $Name -Windows @optionalParams
    }

    function ThenNothingReturned
    {
        $script:servers | Should -BeNullOrEmpty
    }

    function ThenServersReturned
    {
        param(
            [Parameter(Mandatory)]
            [string[]]$Named,

            [string]$WithEncryptionKey
        )

        $script:servers | Should -HaveCount $Named.Count
        foreach( $name in $Named )
        {
            $script:servers | Where-Object { $_.Name -eq $name } | Should -Not -BeNullOrEmpty
        }

        if( $WithEncryptionKey )
        {
            foreach( $server in $script:servers )
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
            $optionalParams['Server'] = $Named
        }
        $script:servers = Get-BMServer -Session $script:session @optionalParams
        if( $script:servers )
        {
            $script:servers | ForEach-Object { $_.pstypenames.Contains( 'Inedo.BuildMaster.Server' ) | Should -BeTrue }
            foreach( $memberName in @( 'name', 'roles', 'environments', 'serverType', 'hostName', 'port', 'encryptionType', 'encryptionKey', 'requireSsl', 'credentialsName', 'tempPath', 'wsManUrl', 'active', 'variables' ) )
            {
                foreach( $server in $script:servers )
                {
                    $server | Get-Member -Name $memberName | Should -Not -BeNullOrEmpty -Because ('member "{0}" should always exist' -f $memberName)
                }
            }
            $keys = $script:servers | Select-Object -ExpandProperty 'encryptionKey' | Where-Object { $_ }
            if( $keys )
            {
                $keys | Should -BeOfType ([securestring])
            }
        }
    }
}

Describe 'Get-BMServer' {
    BeforeEach {
        $Global:Error.Clear()
        Get-BMServer -Session $script:session | Remove-BMServer -Session $script:session
        $script:servers = $null
    }

    It 'should return all servers' {
        GivenServer 'One'
        GivenServer 'Two'
        WhenGettingServers
        ThenServersReturned 'One','Two'
        ThenNoErrorWritten
    }

    It 'should convert server encryption key to a securestring' {
        GivenServer 'One' -WithEncryptionKey '9c59b9ee17824c79a953636416c697ed'
        WhenGettingServers
        ThenServersReturned 'One' -WithEncryptionKey '9c59b9ee17824c79a953636416c697ed'
        ThenNoErrorWritten
    }

    It 'should return specific server by name' {
        GivenServer 'One'
        GivenServer 'Two'
        WhenGettingServers -Named 'One'
        ThenServersReturned 'One'
    }

    It 'should return server by wildcard search' {
        GivenServer 'One'
        GivenServer 'Onf'
        GivenServer 'Two'
        WhenGettingServers -Named 'On*'
        ThenServersReturned 'One','Onf'
    }

    It 'should return nothing by wildcard search that matches no server' {
        GivenServer 'One'
        WhenGettingServers -Named 'Blah*'
        ThenNothingReturned
        ThenNoErrorWritten
    }

    It 'should return nothing' {
        GivenServer 'One'
        WhenGettingServers -Named 'Blah' -ErrorAction SilentlyContinue
        ThenNothingReturned
        ThenError 'does\ not\ exist'
    }

    It 'should ignore errors' {
        GivenServer 'One'
        WhenGettingServers -Named 'Blah' -ErrorAction Ignore
        ThenNothingReturned
        ThenNoErrorWritten
    }
}
