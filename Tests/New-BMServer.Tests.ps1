
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:result = $null

    function GivenEnvironment
    {
        param(
            [Parameter(Mandatory)]
            [string[]]$Named
        )

        foreach( $name in $Named )
        {
            New-BMEnvironment -Session $script:session -Name $name -ErrorAction Ignore
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
            New-BMServer -Session $script:session -Name $Named -Windows
        }
        else
        {
            New-BMServer -Session $script:session -Name $Named @{ $WithType = $true }
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
            New-BMServerRole -Session $script:session -Name $name
        }
    }

    function ThenServerExists
    {
        [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingPlainTextForPassword', '')]
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

        $server = $Named | Get-BMServer -Session $script:session

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

        $Named | Get-BMServer -Session $script:session -ErrorAction Ignore | Should -BeNullOrEmpty
    }

    function WhenCreatingServer
    {
        [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingPlainTextForPassword', '')]
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

        $script:result = New-BMServer -Session $script:session -Name $Named @optionalParams
        $script:result | Should -BeNullOrEmpty
    }
}

Describe 'New-BMServer' {
    BeforeEach {
        $Global:Error.Clear()
        $script:result = $null
        Get-BMServer -Session $script:session | Remove-BMServer -Session $script:session
        Get-BMServerRole -Session $script:session | Remove-BMServerRole -Session $script:session
    }

    It 'should create basic windows server' {
        WhenCreatingServer -Named 'Fubar' -OfType 'windows'
        ThenNoErrorWritten
        ThenServerExists -Named 'Fubar' -OfType 'windows'
    }

    It 'should create local server' {
        WhenCreatingServer -Named 'Fubar' -OfType 'local'
        ThenNoErrorWritten
        ThenServerExists -Named 'Fubar' -OfType 'local'
    }

    It 'should reject server names that end with <_>' -TestCases @('_', '-') {
        $badChar = $_
        $name = 'Fubar{0}' -f $badChar
        { WhenCreatingServer -Named $name -OfType 'windows' } | Should -Throw
        ThenError 'does\ not\ match'
        ThenServerDoesNotExist -Named $name
    }

    It 'should create server with _ and - in the name' {
        $name = 'Fubar_-Snafu'
        WhenCreatingServer -Named $name -OfType 'windows'
        ThenNoErrorWritten
        ThenServerExists -Named $name -OfType 'windows'
    }

    It 'should allow server name one character long' {
        $name = 'F'
        WhenCreatingServer -Named $name -OfType 'windows'
        ThenNoErrorWritten
        ThenServerExists -Named $name -OfType 'windows' -HostName $name
    }

    It 'should reject server name that is too long' {
        $name = 'F' * 51
        { WhenCreatingServer -Named $name -OfType 'windows' } | Should -Throw
        ThenError 'is\ too\ long'
        ThenServerDoesNotExist -Named $name
    }

    It 'should reject server name that already exists' {
        GivenServer -Named 'One' -WithType 'windows'
        WhenCreatingServer -Named 'One' -OfType 'windows' -ErrorAction SilentlyContinue
        ThenError 'already\ exists'
    }

    It 'should ignore errors' {
        GivenServer -Named 'One' -WithType 'windows'
        WhenCreatingServer -Named 'One' -OfType 'windows' -ErrorAction Ignore
        ThenNoErrorWritten
    }

    It 'should support WhatIf' {
        WhenCreatingServer -Named 'One' -OfType 'windows' -WhatIf
        ThenNoErrorWritten
        ThenServerDoesNotExist -Named 'One'
    }

    It 'should create server that uses AES encryption' {
        WhenCreatingServer -Named 'One' -OfType 'windows' -WithEncryptionKey '4F8F4BAC0E664780B63AF3350EB98551'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' `
                         -OfType 'windows' `
                         -WithEncryptionKey '4F8F4BAC0E664780B63AF3350EB98551' `
                         -HostName 'One'
    }

    It 'should create server that uses SSL encryption' -Skip {
        WhenCreatingServer -Named 'One' -OfType 'windows' -Ssl
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'windows' -Ssl -HostName 'One'
    }

    It 'should create server that requires SSL key' {
        WhenCreatingServer -Named 'One' -OfType 'windows' -Ssl -ForceSsl
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'windows' -Ssl -ForceSsl -HostName 'One'
    }

    It 'should create server that uses SSH' {
        WhenCreatingServer -Named 'One' -OfType 'ssh'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'ssh'
    }

    It 'should create server with SSH options' {
        WhenCreatingServer -Named 'One' `
                           -OfType 'ssh' `
                           -CredentialName 'blahblah' `
                           -TempPath '/var/inedo/buildmaster/temp' `
                           -Port 7999 `
                           -HostName 'one.example.com'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' `
                         -OfType 'ssh' `
                         -CredentialName 'blahblah' `
                         -TempPath '/var/inedo/buildmaster/temp' `
                         -HostName 'one.example.com' `
                         -Port 7999
    }

    It 'should create server that uses PowerShell agent' {
        WhenCreatingServer -Named 'One' -OfType 'powershell'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' -OfType 'powershell'
    }

    It 'should create server that customizes PowerShell agent' {
        WhenCreatingServer -Named 'One' `
                           -OfType 'powershell' `
                           -CredentialName 'blahblah' `
                           -TempPath '/var/inedo/buildmaster/temp' `
                           -WSManUrl 'http://example.com'
        ThenNoErrorWritten
        ThenServerExists -Named 'One' `
                         -OfType 'powershell' `
                         -CredentialName 'blahblah' `
                         -TempPath '/var/inedo/buildmaster/temp' `
                         -WSManUrl 'http://example.com'
    }

    It 'should set server roles, environments, and variables' {
        $variables = @{ 'one' = 'a'; 'two' = 'three'; 'four' = 'five'; }
        GivenEnvironment 'one','two'
        GivenServerRole 'role1','role2'
        WhenCreatingServer -Named 'rev' `
                           -OfType 'local' `
                           -InEnvironment 'one','two' `
                           -AsRoles 'role1','role2' `
                           -WithVariables $variables
        ThenNoErrorWritten
        ThenServerExists -Named 'rev' `
                         -OfType 'local' `
                         -Environment 'one','two' `
                         -Role 'role1','role2' `
                         -Variable $variables
    }
}