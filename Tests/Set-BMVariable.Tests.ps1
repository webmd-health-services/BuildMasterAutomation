
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:result = $null

    function GivenApplication
    {
        GivenAnApplication -Name $PSCommandPath
    }

    function GivenApplicationGroup
    {
        param(
            [Parameter(Mandatory)]
            [string] $Named
        )

        Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_CreateOrUpdateApplicationGroup' -Method Post -Parameter @{ 'ApplicationGroup_Name' = $Named }
    }

    function GivenEnvironment
    {
        param(
            [Parameter(Mandatory)]
            [string] $Named
        )

        New-BMEnvironment -Session $script:session -Name $Named -ErrorAction Ignore
        Get-BMVariable -Session $script:session -Environment $Named |
            Remove-BMVariable -Session $script:session -Environment $Named
    }

    function GivenServer
    {
        param(
            [Parameter(Mandatory)]
            [string] $Named
        )

        $Named | Get-BMServer -Session $script:session -ErrorAction Ignore | Remove-BMServer -Session $script:session
        New-BMServer -Session $script:session -Name $Named -Local
    }

    function GivenServerRole
    {
        param(
            [Parameter(Mandatory)]
            [string] $Named
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

            [switch] $Raw
        )

        $optionalParams = @{ }
        if ($ForApplication)
        {
            $optionalParams['Application'] = $ForApplication
        }

        if ($ForApplicationGroup)
        {
            $optionalParams['ApplicationGroup'] = $ForApplicationGroup
        }

        if ($ForEnvironment)
        {
            $optionalParams['Environment'] = $ForEnvironment
        }

        if ($ForServer)
        {
            $optionalParams['Server'] = $ForServer
        }

        if ($ForServerRole)
        {
            $optionalParams['ServerRole'] = $ForServerRole
        }

        if ($Raw)
        {
            $optionalParams['Raw'] = $true
        }

        Set-BMVariable -Session $script:session -Name $Named -Value $WithValue @optionalParams
    }

    function ThenVariableSet
    {
        param(
            [Parameter(Mandatory)]
            [string] $Named,

            [Parameter(Mandatory)]
            [AllowEmptyString()]
            [string] $To,

            [string] $ForApplication,

            [string] $ForApplicationGroup,

            [string] $ForEnvironment,

            [string] $ForServer,

            [string] $ForServerRole,

            [Object] $ForRelease,

            [Object] $ForBuild
        )

        $optionalParams = @{ }

        if ($ForApplication)
        {
            $optionalParams['Application'] = $ForApplication
        }

        if ($ForApplicationGroup)
        {
            $optionalParams['ApplicationGroup'] = $ForApplicationGroup
        }

        if ($ForEnvironment)
        {
            $optionalParams['Environment'] = $ForEnvironment
        }

        if ($ForServer)
        {
            $optionalParams['Server'] = $ForServer
        }

        if ($ForServerRole)
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

        $actualValue = $Named | Get-BMVariable -Session $script:session @optionalParams -ValueOnly -Raw
        $actualValue | Should -Be $To
    }

    function WhenSettingVariable
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [Alias('Named')]
            [String] $Name,

            [Parameter(Mandatory)]
            [Alias('WithValue')]
            [Object] $Value,

            [Alias('ForApplication')]
            [String] $Application,

            [Alias('ForApplicationGroup')]
            [String] $ApplicationGroup,

            [Alias('ForEnvironment')]
            [String] $Environment,

            [Alias('ForServer')]
            [String] $Server,

            [Alias('ForServerRole')]
            [String] $ServerRole,

            [Alias('ForRelease')]
            [Object] $Release,

            [Alias('ForBuild')]
            [Object] $Build,

            [switch] $Raw,
            [Switch] $WhatIf
        )

        $script:result = Set-BMVariable -Session $script:session @PSBoundParameters
        $script:result | Should -BeNullOrEmpty
    }
}

Describe 'Set-BMVariable' {
    BeforeEach {
        $Global:Error.Clear()
        $script:result = $null
        Get-BMVariable -Session $script:session | Remove-BMVariable -Session $script:session
        # Remove all application groups.
        Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_GetApplicationGroups' -Method Get |
            ForEach-Object { Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_DeleteApplicationGroup' -Method Post -Parameter @{ 'ApplicationGroup_Id' = $_.ApplicationGroup_Id } }
    }

    It 'should create global variable' {
        WhenSettingVariable 'GlobalVar' -WithValue 'GlobalValue'
        ThenVariableSet 'GlobalVar' -To 'GlobalValue'
        ThenNoErrorWritten
    }

    It 'should update existing variable' {
        GivenVariable 'GlobalVar' -WithValue 'OldValue'
        WhenSettingVariable 'GlobalVar' -WithValue 'NewValue'
        ThenVariableSet 'GlobalVar' -To 'NewValue'
        ThenNoErrorWritten
    }

    It 'should encode variable name' {
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        Mock -CommandName 'Get-BMEnvironment' `
             -ModuleName 'BuildMasterAutomation' `
             -MockWith { return [pscustomobject]@{ 'Environment_Name' = 'Get BMVariable' }}
        WhenSettingVariable 'F u b a r' -WithValue 'Varlue' -ForEnvironment 'Get BMVariable'
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter { $Name -eq 'variables/environment/Get%20BMVariable/F%20u%20b%20a%20r' }
        ThenNoErrorWritten
    }

    It 'should create application variable' {
        $app = GivenAnApplication -Name 'Set-BMVariable'
        WhenSettingVariable 'AppFubar' -WithValue 'AppValue' -ForApplication $app.Application_Name
        ThenVariableSet 'AppFubar' -To 'AppValue' -ForApplication $app.Application_Name
        ThenNoErrorWritten
    }

    It 'should create application group variable' {
        GivenApplicationGroup 'fizzbuzz'
        WhenSettingVariable 'AppGroupFubar' -WithValue 'AppGropuValue' -ForApplicationGroup 'fizzbuzz'
        ThenVariableSet 'AppGroupFubar' -To 'AppGropuValue' -ForApplicationGroup 'fizzbuzz'
        ThenNoErrorWritten
    }

    It 'should create environment-scoped variable' {
        GivenEnvironment 'SetBMVariable'
        WhenSettingVariable 'EnvironmentFubar' -WithValue 'EnvValue' -ForEnvironment 'SetBMVariable'
        ThenVariableSet 'EnvironmentFubar' -To 'EnvValue' -ForEnvironment 'SetBMVariable'
        ThenNoErrorWritten
    }

    It 'should create server variable' {
        GivenServer 'SetBMVariable'
        WhenSettingVariable 'ServerVar' -WithValue 'ServerValue' -ForServer 'SetBMVariable'
        ThenVariableSet 'ServerVar' -To 'ServerValue' -ForServer 'SetBMVariable'
        ThenNoErrorWritten
    }

    It 'should create server role variable' {
        GivenServerRole 'SetBMVariable'
        WhenSettingVariable 'ServerRoleVar' -WithValue 'ServerRoleValue' -ForServerRole 'SetBMVariable'
        ThenVariableSet 'ServerRoleVar' -To 'ServerRoleValue' -ForServerRole 'SetBMVariable'
        ThenNoErrorWritten
    }

    It 'should create release variable' {
        $application = GivenAnApplication -Name 'Set-BMVariable'
        $pipeline = GivenAPipeline -Named 'Set-BMVariable' -ForApplication $application
        $release = GivenARelease -Named 'Set-BMVariable' -ForApplication $application -WithNumber '1.0' -UsingPipeline $pipeline
        WhenSettingVariable 'ReleaseVar' -WithValue 'ReleaseVarValue' -ForRelease $release
        ThenVariableSet 'ReleaseVar' -To 'ReleaseVarValue' -ForRelease $release
        ThenNoErrorWritten
    }

    It 'should create build variable' {
        $application = GivenAnApplication -Name 'Set-BMVariable'
        $pipeline = GivenAPipeline -Named 'Set-BMVariable' -ForApplication $application
        $release = GivenARelease -Named 'Set-BMVariable' -ForApplication $application -WithNumber '1.0' -UsingPipeline $pipeline
        $build = GivenABuild -ForRelease $release
        WhenSettingVariable 'BuildVar' -WithValue 'BuildVarValue' -ForBuild $build
        ThenVariableSet 'BuildVar' -To 'BuildVarValue' -ForBuild $build
        ThenNoErrorWritten
    }

    It 'should convert map to OtterScript map' {
        WhenSettingVariable 'GlobalVar' -WithValue @{ 'hello' = 'world' }
        ThenVariableSet 'GlobalVar' -To '%(hello: world)'
        ThenNoErrorWritten
    }

    It 'should convert array to OtterScript vector' {
        WhenSettingVariable 'GlobalVar' -WithValue @('some', 'vector')
        ThenVariableSet 'GlobalVar' -To '@(some, vector)'
        ThenNoErrorWritten
    }

    It 'should support an empty variable' {
        GivenVariable 'EmptyVar' -WithValue 'OldValue'
        WhenSettingVariable 'EmptyVar' -WithValue ''
        ThenVariableSet 'EmptyVar' -To ''
        ThenNoErrorWritten
    }

    It 'should support an empty PowerShell array' {
        WhenSettingVariable 'GlobalVar' -WithValue @()
        ThenVariableSet 'GlobalVar' -To '@()'
        ThenNoErrorWritten
    }

    It 'should support an empty PowerShell hashtable' {
        WhenSettingVariable 'GlobalVar' -WithValue @{}
        ThenVariableSet 'GlobalVar' -To '%()'
        ThenNoErrorWritten
    }

    It 'should not convert value when using Raw' {
        Mock -CommandName 'ConvertTo-BMOtterScriptExpression' -ModuleName 'BuildMasterAutomation'
        WhenSettingVariable 'RawVar' -WithValue '@(one, two, three)' -Raw
        Should -Not -Invoke 'ConvertTo-BMOtterScriptExpression' -ModuleName 'BuildMasterAutomation'
        ThenVariableSet 'RawVar' -To '@(one, two, three)'
        ThenNoErrorWritten
    }

    It 'should fail to set variable' {
        $value = [System.Collections.DictionaryEntry]::new('hello', 'world')
        WhenSettingVariable 'GlobalVar' -WithValue $value -ErrorAction SilentlyContinue
        ThenError -MatchesPattern 'Unable to convert*'
    }

    It 'should support WhatIf when creating variable' {
        WhenSettingVariable 'GlobalVar' -WithValue 'GlobalValue' -WhatIf
        'GlobalVar' | Get-BMVariable -Session $script:session -ErrorAction Ignore | Should -BeNullOrEmpty
        ThenNoErrorWritten
    }

    It 'should support WhatIf and updating a variable' {
        GivenVariable 'GlobalVar' -WithValue 'OldValue'
        WhenSettingVariable 'GlobalVar' -WithValue 'NewValue' -WhatIf
        ThenVariableSet 'GlobalVar' -To 'OldValue'
        ThenNoErrorWritten
    }
}