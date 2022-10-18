
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

    function ThenVariableRemoved
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named,

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

        $actualValue = Get-BMVariable -Session $script:session -Name $Named @optionalParams -ErrorAction Ignore
        $actualValue | Should -BeNullOrEmpty
    }

    function WhenRemovingVariable
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Named,
            [string]$ForApplication,
            [string]$ForApplicationGroup,
            [string]$ForEnvironment,
            [string]$ForServer,
            [string]$ForServerRole,
            [Switch]$WhatIf
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

        if( $WhatIf )
        {
            $optionalParams['WhatIf'] = $true
        }

        $script:result = Remove-BMVariable -Session $script:session -Name $Named @optionalParams
        $script:result | Should -BeNullOrEmpty
    }
}

Describe 'Remove-BMVariable' {
    BeforeEach {
        $Global:Error.Clear()
        $script:result = $null
        Get-BMVariable -Session $script:session | Remove-BMVariable -Session $script:session
        # Remove all application groups.
        Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_GetApplicationGroups' -Method Get |
            ForEach-Object { Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_DeleteApplicationGroup' -Method Post -Parameter @{ 'ApplicationGroup_Id' = $_.ApplicationGroup_Id } }
    }

    It 'should remove global variable' {
        GivenVariable 'GlobalVar' -WithValue 'GlobalValue'
        WhenRemovingVariable 'GlobalVar'
        ThenVariableRemoved 'GlobalVar'
        ThenNoErrorWritten
    }

    It 'should ignore variable that does not exist' {
        WhenRemovingVariable 'GlobalVar'
        ThenNoErrorWritten
    }

    It 'should ignore variable that does not exist' {
        WhenRemovingVariable 'EnvVar' -ForEnvironment 'HouseCarpenter' -ErrorAction Ignore
        ThenNoErrorWritten
    }

    It 'should encode variable and scope names' {
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        WhenRemovingVariable '?V a r&' -ForEnvironment '?E n v&'
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter { $Name -eq 'variables/environment/%3FE%20n%20v%26/%3FV%20a%20r%26' }
        ThenNoErrorWritten
    }

    It 'should remove application variable' {
        $app = GivenApplication
        GivenVariable -Named 'AppFubar' -WithValue 'AppValue' -ForApplication $app.Application_Name
        WhenRemovingVariable 'AppFubar' -ForApplication $app.Application_Name
        ThenVariableRemoved 'AppFubar' -ForApplication $app.Application_Name
        ThenNoErrorWritten
    }

    It 'should reject removing variable from application that does not exist' {
        WhenRemovingVariable 'AppFubar' -ForApplication 'ItIsHardTimes' -ErrorAction SilentlyContinue
        ThenError 'does\ not\ exist'
    }

    It 'should ignore removing variable from application that does not exist' {
        WhenRemovingVariable 'AppFubar' -ForApplication 'ItIsHardTimes' -ErrorAction Ignore
        ThenNoErrorWritten
    }

    It 'should remove application group variable' {
        GivenApplicationGroup 'fizzbuzz'
        GivenVariable -Named 'AppGroupFubar' -WithValue 'AppGropuValue' -ForApplicationGroup 'fizzbuzz'
        WhenRemovingVariable 'AppGroupFubar' -ForApplicationGroup 'fizzbuzz'
        ThenVariableRemoved 'AppGroupFubar' -ForApplicationGroup 'fizzbuzz'
        ThenNoErrorWritten
    }

    It 'should reject removing variable from non-existent application group' {
        WhenRemovingVariable 'AppGroupFubar' -ForApplicationGroup 'SmogInCalifornia' -ErrorAction SilentlyContinue
        ThenError 'does\ not\ exist'
    }

    It 'should ignore removing variable from non-existent application group' {
        WhenRemovingVariable 'AppGroupFubar' -ForApplicationGroup 'SmogInCalifornia' -ErrorAction Ignore
        ThenNoErrorWritten
    }

    It 'should remove environment-scoped variable' {
        GivenEnvironment 'RemoveBMVariable'
        GivenVariable -Named 'EnvironmentFubar' -WithValue 'EnvValue' -ForEnvironment 'RemoveBMVariable'
        WhenRemovingVariable 'EnvironmentFubar' -ForEnvironment 'RemoveBMVariable'
        ThenVariableRemoved 'EnvironmentFubar' -ForEnvironment 'RemoveBMVariable'
        ThenNoErrorWritten
    }

    It 'should reject removing variable from non-existent environment' {
        WhenRemovingVariable 'EnvironmentFubar' -ForEnvironment 'EnvThatDoesNotExist' -ErrorAction SilentlyContinue
        ThenError 'specified environment was not found'
    }

    It 'should ignore removing variable from non-existent environment' {
        WhenRemovingVariable 'EnvironmentFubar' -ForEnvironment 'EnvThatDoesNotExist' -ErrorAction Ignore
        ThenNoErrorWritten
    }

    It 'should remove server variable' {
        GivenServer 'RemoveBMVariable'
        GivenVariable -Named 'ServerVar' -WithValue 'ServerValue' -ForServer 'RemoveBMVariable'
        WhenRemovingVariable 'ServerVar' -ForServer 'RemoveBMVariable'
        ThenVariableRemoved 'ServerVar' -ForServer 'RemoveBMVariable'
        ThenNoErrorWritten
    }

    It 'should remove server role variable' {
        GivenServerRole 'RemoveBMVariable'
        GivenVariable -Named 'ServerRoleVar' -WithValue 'ServerRoleValue' -ForServerRole 'RemoveBMVariable'
        WhenRemovingVariable 'ServerRoleVar' -ForServerRole 'RemoveBMVariable'
        ThenVariableRemoved 'ServerRoleVar' -ForServerRole 'RemoveBMVariable'
        ThenNoErrorWritten
    }

    It 'should support WhatIf' {
        GivenVariable 'WhatIfVar' -WithValue 'WhatIfValue'
        WhenRemovingVariable 'WhatIfVar' -WhatIf
        Get-BMVariable -Session $script:session -Name 'WhatIfVar' -ValueOnly | Should -Be 'WhatIfValue'
        ThenNoErrorWritten
    }
}