
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:result = $null

    function GivenApplication
    {
        New-BMTestApplication -Session $script:session -CommandPath $PSCommandPath
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
            [string] $To,

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

        $actualValue = $Named | Get-BMVariable -Session $script:session @optionalParams -ValueOnly
        $actualValue | Should -Not -BeNullOrEmpty
        $actualValue | Should -Be $To
    }

    function WhenSettingVariable
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String] $Named,
            [Parameter(Mandatory)]
            [Object] $WithValue,
            [String] $ForApplication,
            [String] $ForApplicationGroup,
            [String] $ForEnvironment,
            [String] $ForServer,
            [String] $ForServerRole,
            [Switch] $WhatIf
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

        if ($WhatIf)
        {
            $optionalParams['WhatIf'] = $true
        }

        $script:result = Set-BMVariable -Session $script:session -Name $Named -Value $WithValue -ErrorAction 'SilentlyContinue' @optionalParams
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
        $app = GivenApplication
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

    It 'should convert map to OtterScript map' {
        WhenSettingVariable 'GlobalVar' -WithValue @{ 'hello' = 'world' }
        ThenVariableSet 'GlobalVar' -To '%(hello: world)' -Raw
    }

    It 'should convert array to OtterScript vector' {
        WhenSettingVariable 'GlobalVar' -WithValue @('some', 'vector')
        ThenVariableSet 'GlobalVar' -To '@(some, vector)' -Raw
    }

    It 'should fail to set variable' {
        $value = [System.Collections.DictionaryEntry]::new('hello', 'world')
        WhenSettingVariable 'GlobalVar' -WithValue $value
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