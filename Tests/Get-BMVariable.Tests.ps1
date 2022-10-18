
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
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
        Enable-BMEnvironment -Session $script:session -Name $Named
        Get-BMVariable -Session $script:session -EnvironmentName $Named | Remove-BMVariable -Session $script:session -EnvironmentName $Named
    }

    function GivenServer
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        Get-BMServer -Session $script:session -Name $Named -ErrorAction Ignore | Remove-BMServer -Session $script:session
        New-BMServer -Session $script:session -Name $Named -Local
    }

    function GivenServerRole
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        Get-BMServerRole -Session $script:session -Name $Named -ErrorAction Ignore | Remove-BMServerRole -Session $script:session
        New-BMServerRole -Session $script:session -Name $Named
    }

    function GivenVariable
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named,

            [Parameter(Mandatory)]
            [string]$WithValue,

            [string]$ForApplication,

            [string]$ForApplicationGroup,

            [string]$ForEnvironment,

            [string]$ForServer,

            [string]$ForServerRole
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
            [string]$ForServerRole
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

        $script:result = Get-BMVariable -Session $script:session @optionalParams
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

    It 'should return variable when searchging by name' {
        GivenVariable 'Fubar' -WithValue 'Snafu'
        GivenVariable 'Snafu' -WithValue 'Fubar'
        WhenGettingVariable 'Fubar'
        ThenVariableReturned @{ 'Fubar' = 'Snafu' }
        ThenNoErrorWritten
    }

    Context 'when getting variable that does not exist' {
        It 'should fail' {
            WhenGettingVariable 'IDONOTEXIST!!!!!!' -ErrorAction SilentlyContinue
            ThenNothingReturned
            ThenError 'does\ not\ exist'
        }

        It 'should ignore errors' {
            WhenGettingVariable 'IDONOTEXIST!!!!!!' -ErrorAction Ignore
            ThenNothingReturned
            ThenNoErrorWritten
        }
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
        $app = GivenApplication
        GivenVariable 'AppFubar' -WithValue 'Snafu' -ForApplication $app.Application_Name
        $WhatIfPreference = $true
        WhenGettingVariable 'AppFubar' -ForApplication $app.Application_Name
        $WhatIfPreference | Should -BeTrue
        $WhatIfPreference = $false
        ThenVariableReturned @{ 'AppFubar' = 'Snafu' }
        ThenNoErrorWritten
    }

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

    It 'should URL-encode variable names' {
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        WhenGettingVariable 'EnvironmentFubar' -ForEnvironment 'Get BMVariable'
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter { $Name -eq 'variables/environment/Get%20BMVariable' }
        ThenNoErrorWritten
    }

    It 'should write an error when server does not exist' {
        WhenGettingVariable -Named 'Nope' -ForServer 'Nope' -ErrorAction SilentlyContinue
        ThenError 'server\ was\ not\ found'
        ThenNothingReturned
    }

    It 'should write an error when server role does not exist' {
        WhenGettingVariable -Named 'Nope' -ForServerRole 'Nope' -ErrorAction SilentlyContinue
        ThenError 'role\ was\ not\ found'
        ThenNothingReturned
    }

    It 'should write an error when environment does not exist' {
        WhenGettingVariable -Named 'Nope' -ForEnvironment 'Nope' -ErrorAction SilentlyContinue
        ThenError 'environment\ was\ not\ found'
        ThenNothingReturned
    }

    It 'should write an error when application does not exist' {
        WhenGettingVariable -Named 'Nope' -ForApplication 'Nope' -ErrorAction SilentlyContinue
        ThenError 'application\ "Nope"\ does\ not\ exist'
        ThenNothingReturned
    }

    It 'should write an error when application group does not exist' {
        WhenGettingVariable -Named 'Nope' -ForApplicationGroup 'Nope' -ErrorAction SilentlyContinue
        ThenError 'application\ group\ "Nope"\ does\ not\ exist'
        ThenNothingReturned
    }

    Context 'when ignoring errors' {
        It 'should not write an error for missing application' {
            WhenGettingVariable -Named 'Nope' -ForApplication 'Nope' -ErrorAction Ignore
            ThenNoErrorWritten
            ThenNothingReturned
        }

        It 'should not write an error for missing application group' {
            WhenGettingVariable -Named 'Nope' -ForApplicationGroup 'Nope' -ErrorAction Ignore
            ThenNoErrorWritten
            ThenNothingReturned
        }
    }
}