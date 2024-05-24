
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:result = $null

    function GivenApplication
    {
        New-BMTestApplication -Session $script:session -CommandPath $PSCommandPath | Write-Output
    }

    function GivenApplicationGroup
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_CreateOrUpdateApplicationGroup' -Method Post -Parameter @{ 'ApplicationGroup_Name' = $Named }
    }

    function GivenEnvironment
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        New-BMEnvironment -Session $script:session -Name $Named -ErrorAction Ignore
        Get-BMVariable -Session $script:session -Environment $Named |
            Remove-BMVariable -Session $script:session -Environment $Named
    }

    function GivenServer
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        $Named |
            Get-BMServer -Session $script:session -ErrorAction Ignore |
            Remove-BMServer -Session $script:session
        New-BMServer -Session $script:session -Name $Named -Local
    }

    function GivenServerRole
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        $Named |
            Get-BMServerRole -Session $script:session -ErrorAction Ignore |
            Remove-BMServerRole -Session $script:session
        New-BMServerRole -Session $script:session -Name $Named
    }

    function GivenVariable
    {
        param(
            [Parameter(Mandatory)]
            [string] $Named,

            [Parameter(Mandatory)]
            [string] $WithValue,

            [string] $ForApplication,

            [string] $ForApplicationGroup,

            [string] $ForEnvironment,

            [string] $ForServer,

            [string] $ForServerRole,

            [Object] $ForRelease,

            [Object] $ForBuild
        )

        $optionalParams = @{ }
        if( $ForApplication )
        {
            $optionalParams['ApplicationName'] = $ForApplication
        }

        if( $ForApplicationGroup )
        {
            $optionalParams['ApplicationGroupName'] = $ForApplicationGroup
        }

        if( $ForEnvironment )
        {
            $optionalParams['EnvironmentName'] = $ForEnvironment
        }

        if( $ForServer )
        {
            $optionalParams['ServerName'] = $ForServer
        }

        if( $ForServerRole )
        {
            $optionalParams['ServerRoleName'] = $ForServerRole
        }

        if( $ForRelease )
        {
            $optionalParams['Release'] = $ForRelease
        }

        if( $ForBuild )
        {
            $optionalParams['Build'] = $ForBuild
        }

        Set-BMVariable -Session $script:session -Name $Named -Value $WithValue @optionalParams
    }

    function ThenNothingReturned
    {
        $script:result | Should -BeNullOrEmpty
    }

    function ThenVariableReturned
    {
        param(
            [Parameter(Mandatory)]
            [hashtable]$Variable
        )

        $script:result | Should -Not -BeNullOrEmpty
        [string[]]$expectedVariableName = $Variable.Keys
        $script:result | Should -HaveCount $expectedVariableName.Count
        foreach( $variableName in $expectedVariableName )
        {
            $actualVariable = $script:result | Where-Object { $_.Name -eq $variableName }
            $actualVariable | Should -Not -BeNullOrEmpty
            $actualVariable.Value | Should -Be $Variable[$variableName]
        }
    }

    function ThenVariableValuesReturned
    {
        param(
            [Parameter(Mandatory)]
            [string[]]$Value
        )

        $script:result | Should -Not -BeNullOrEmpty
        $script:result | Should -HaveCount $Value.Count
        $script:result | Should -Be $Value
    }

    function WhenGettingVariable
    {
        [CmdletBinding()]
        param(
            [string]$Named,
            [Switch]$ValueOnly,
            [string]$ForApplication,
            [string]$ForApplicationGroup,
            [string]$ForEnvironment,
            [string]$ForServer,
            [string]$ForServerRole,
            [object]$ForRelease,
            [object]$ForBuild,
            [switch]$Raw
        )

        $optionalParams = @{ }

        if( $Named )
        {
            $optionalParams['Name'] = $Named
        }

        if( $ValueOnly )
        {
            $optionalParams['ValueOnly'] = $true
        }

        if ( $Raw )
        {
            $optionalParams['Raw'] = $true
        }

        if( $ForApplication )
        {
            $optionalParams['Application'] = $ForApplication
        }

        if( $ForApplicationGroup )
        {
            $optionalParams['ApplicationGroup'] = $ForApplicationGroup
        }

        if( $ForEnvironment )
        {
            $optionalParams['Environment'] = $ForEnvironment
        }

        if( $ForServer )
        {
            $optionalParams['Server'] = $ForServer
        }

        if( $ForServerRole )
        {
            $optionalParams['ServerRole'] = $ForServerRole
        }

        if ($ForRelease)
        {
            $optionalParams['Release'] = $ForRelease
        }

        if ($ForBuild)
        {
            $optionalParams['Build'] = $ForBuild
        }

        $script:result = Get-BMVariable -Session $script:session @optionalParams
    }

    function GivenVectorVariable
    {
        param(
            [string] $Name,
            [string[]] $List,
            [int] $Id
        )

        $otterScriptVect = "@($($List -join ', '))"
        $bytes = [Text.Encoding]::UTF8.GetBytes($otterScriptVect)
        $base64Val = [Convert]::ToBase64String($bytes)

        Invoke-BMNativeApiMethod -Session $script:session `
                                 -Name 'Variables_CreateOrUpdateVariable' `
                                 -Method Post `
                                 -Parameter @{
                                    Variable_Name = $name
                                    Variable_Value = $base64Val
                                    ValueType_Code = 'V'
                                    Application_Id = $Id
                                 }
    }
}

Describe 'Get-BMVariable' {
    BeforeEach {
        $Global:Error.Clear()
        $script:result = $null
        Get-BMVariable -Session $script:session | Remove-BMVariable -Session $script:session
        # Remove all application groups.
        Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_GetApplicationGroups' -Method Get |
            ForEach-Object { Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_DeleteApplicationGroup' -Method Post -Parameter @{ 'ApplicationGroup_Id' = $_.ApplicationGroup_Id } }
    }

    It 'should return nothing' {
        WhenGettingVariable
        ThenNothingReturned
        ThenNoErrorWritten
    }

    It 'should return variable when searching by name' {
        GivenVariable 'Fubar' -WithValue 'Snafu'
        GivenVariable 'Snafu' -WithValue 'Fubar'
        WhenGettingVariable 'Fubar'
        ThenVariableReturned @{ 'Fubar' = 'Snafu' }
        ThenNoErrorWritten
    }

    It 'should fail for variable that does not exist' {
        $Global:Error.Clear()
        WhenGettingVariable 'IDONOTEXIST!!!!!!' -ErrorAction SilentlyContinue
        ThenNothingReturned
        ThenError -AtIndex 0 'does\ not\ exist'
    }

    It 'should ignore errors for variable does not exist' {
        WhenGettingVariable 'IDONOTEXIST!!!!!!' -ErrorAction Ignore
        ThenNothingReturned
        ThenNoErrorWritten
    }

    It 'should allow wildcards that do not match any variables' {
        WhenGettingVariable 'IDONOTEXIST*'
        ThenNothingReturned
        ThenNoErrorWritten
    }

    It 'should return all variables' {
        GivenVariable 'Fubar' -WithValue 'Snafu'
        GivenVariable 'Snafu' -WithValue 'Fubar'
        WhenGettingVariable
        ThenVariableReturned @{ 'Fubar' = 'Snafu'; 'Snafu' = 'Fubar' }
        ThenNoErrorWritten
    }

    It 'should return just values' {
        GivenVariable 'Fubar' -WithValue 'Snafu'
        GivenVariable 'Snafu' -WithValue 'Fubar'
        WhenGettingVariable -ValueOnly
        ThenVariableValuesReturned @( 'Snafu', 'Fubar' )
        ThenNoErrorWritten
    }

    It 'should return as value if variable is not OtterScript vector' {
        GivenVariable 'Fubar' -WithValue 'Snafu'
        WhenGettingVariable -ValueOnly
        ThenVariableValuesReturned 'Snafu'
        ThenNoErrorWritten
    }

    It 'should return item as an array' {
        $app = GivenApplication
        GivenVectorVariable -Name 'ArrItem' -List @( 'hello', 'world' ) -Id $app.Application_Id
        WhenGettingVariable -ValueOnly -ForApplication $app.Application_Name
        ThenVariableValuesReturned @( 'hello', 'world' )
        ThenNoErrorWritten
    }

    It 'should return item as a string' {
        $app = GivenApplication
        GivenVectorVariable -Name 'ArrItem' -List @( 'hello', 'world' ) -Id $app.Application_Id
        WhenGettingVariable -ValueOnly -ForApplication $app.Application_Name -Raw
        ThenVariableValuesReturned '@(hello, world)'
        ThenNoErrorWritten
    }

    It 'should return specific variable''s value' {
        GivenVariable 'Fubar' -WithValue 'Snafu'
        GivenVariable 'Snafu' -WithValue 'Fubar'
        WhenGettingVariable 'Snafu' -ValueOnly
        ThenVariableValuesReturned 'Fubar'
    }

    It 'should return the variables for an application' {
        $app = GivenApplication
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'AppFubar' -WithValue 'Snafu' -ForApplication $app.Application_Name
        WhenGettingVariable 'AppFubar' -ForApplication $app.Application_Name
        ThenVariableReturned @{ 'AppFubar' = 'Snafu' }
        ThenNoErrorWritten
    }

    It 'should ignore WhatIf' {
        GivenVariable 'AppFubar' -WithValue 'Snafu'
        $WhatIfPreference = $true
        WhenGettingVariable 'AppFubar'
        $WhatIfPreference | Should -BeTrue
        $WhatIfPreference = $false
        ThenVariableReturned @{ 'AppFubar' = 'Snafu' }
        ThenNoErrorWritten
    }

    # Doesn't currently work in BuildMaster.
    It 'should return application group''s variable' {
        GivenApplicationGroup 'fizzbuzz'
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'AppGroupFubar' -WithValue 'Snafu' -ForApplicationGroup 'fizzbuzz'
        WhenGettingVariable 'AppGroupFubar' -ForApplicationGroup 'fizzbuzz'
        ThenVariableReturned @{ 'AppGroupFubar' = 'Snafu' }
        ThenNoErrorWritten
    }

    It 'should return an environment''s variable' {
        GivenEnvironment 'GetBMVariable'
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'EnvironmentFubar' -WithValue 'Snafu' -ForEnvironment 'GetBMVariable'
        WhenGettingVariable 'EnvironmentFubar' -ForEnvironment 'GetBMVariable'
        ThenVariableReturned @{ 'EnvironmentFubar' = 'Snafu' }
        ThenNoErrorWritten
    }

    It 'should return a server variable' {
        GivenServer 'GetBMVariable'
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'ServerVar' -WithValue 'ServerValue' -ForServer 'GetBMVariable'
        WhenGettingVariable 'ServerVar' -ForServer 'GetBMVariable'
        ThenVariableReturned @{ 'ServerVar' = 'ServerValue' }
        ThenNoErrorWritten
    }

    It 'should return a server role variable' {
        GivenServerRole 'GetBMVariable'
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'ServerRoleVar' -WithValue 'ServerRoleValue' -ForServerRole 'GetBMVariable'
        WhenGettingVariable 'ServerRoleVar' -ForServerRole 'GetBMVariable'
        ThenVariableReturned @{ 'ServerRoleVar' = 'ServerRoleValue' }
        ThenNoErrorWritten
    }

    It 'should return a release variable' {
        $application = GivenAnApplication -Name 'Get-BMVariable'
        $pipeline = GivenAPipeline -Named 'Get-BMVariable' -ForApplication $application
        $release = GivenARelease -Named 'Get-BMVariable' -ForApplication $application -WithNumber '1.0' -UsingPipeline $pipeline
        GivenVariable 'ReleaseVar' -WithValue 'ReleaseValue' -ForRelease $release
        WhenGettingVariable 'ReleaseVar' -ForRelease $release -ValueOnly
        ThenVariableValuesReturned 'ReleaseValue'
        ThenNoErrorWritten
    }

    It 'should return a build variable' {
        $application = GivenAnApplication -Name 'Get-BMVariable'
        $pipeline = GivenAPipeline -Named 'Get-BMVariable' -ForApplication $application
        $release = GivenARelease -Named 'Get-BMVariable' -ForApplication $application -WithNumber '1.0' -UsingPipeline $pipeline
        $build = GivenABuild -ForRelease $release
        GivenVariable 'BuildVar' -WithValue 'BuildValue' -ForBuild $build
        WhenGettingVariable 'BuildVar' -ForBuild $build -ValueOnly
        ThenVariableValuesReturned 'BuildValue'
        ThenNoErrorWritten
    }

    It 'should URL-encode variable names' {
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation' -MockWith {
            [pscustomobject]@{
                Name = 'URL Encode Me!'
                Value = 'ok'
            }
        }
        WhenGettingVariable 'URL Encode Me!'
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter {
                                $expectedName = "variables/global/$([Uri]::EscapeDataString('URL Encode Me!'))"
                                return $Name -eq $expectedName
                            }
        ThenNoErrorWritten
    }

    It 'should write an error when server does not exist' {
        WhenGettingVariable -Named 'Nope' -ForServer 'Nope' -ErrorAction SilentlyContinue
        ThenError ([regex]::Escape('server "Nope" does not exist'))
        ThenNothingReturned
    }

    It 'should write an error when server role does not exist' {
        WhenGettingVariable -Named 'Nope' -ForServerRole 'Nope' -ErrorAction SilentlyContinue
        ThenError ([regex]::Escape('server role "Nope" does not exist'))
        ThenNothingReturned
    }

    It 'should write an error when environment does not exist' {
        WhenGettingVariable -Named 'Nope' -ForEnvironment 'Nope' -ErrorAction SilentlyContinue
        ThenError ([regex]::Escape('environment "Nope" does not exist'))
        ThenNothingReturned
    }

    It 'should write an error when application does not exist' {
        WhenGettingVariable -Named 'Nope' -ForApplication 'Nope' -ErrorAction SilentlyContinue
        ThenError ([regex]::Escape('application "Nope" does not exist'))
        ThenNothingReturned
    }

    It 'should write an error when application group does not exist' {
        WhenGettingVariable -Named 'Nope' -ForApplicationGroup 'Nope' -ErrorAction SilentlyContinue
        ThenError ([regex]::Escape('application group "Nope" does not exist'))
        ThenNothingReturned
    }

    It 'should write an error when the Release parameter is not an object' {
        WhenGettingVariable -Named 'Nope' -ForRelease 'somerelease' -ErrorAction SilentlyContinue
        ThenError ([regex]::Escape('must be a Release object'))
        ThenNothingReturned
    }

    It 'should write an error when the Build parameter is not an object' {
        WhenGettingVariable -Named 'Nope' -ForBuild 123 -ErrorAction SilentlyContinue
        ThenError ([regex]::Escape('must be a Build object'))
        ThenNothingReturned
    }

    It 'should ignore errors for missing application' {
        WhenGettingVariable -Named 'Nope' -ForApplication 'Nope' -ErrorAction Ignore
        ThenNoErrorWritten
        ThenNothingReturned
    }

    It 'should ignore errors for missing application group' {
        WhenGettingVariable -Named 'Nope' -ForApplicationGroup 'Nope' -ErrorAction Ignore
        ThenNoErrorWritten
        ThenNothingReturned
    }
}