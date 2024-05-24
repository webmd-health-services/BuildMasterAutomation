
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:result = $null

    function GivenApplication
    {
        param(
            [String] $Named
        )

        $optionalArgs = @{}
        if ($Named)
        {
            $optionalArgs['Name'] = $Named
        }
        else
        {
            $optionalArgs['CommandPath'] = $PSCommandPath
        }

        New-BMTestApplication -Session $script:session @optionalArgs
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

        $Named | Get-BMServer -Session $script:session -ErrorAction Ignore | Remove-BMServer -Session $script:session
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
            [AllowEmptyString()]
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

        if ($ForRelease)
        {
            $optionalParams['Release'] = $ForRelease
        }

        if ($ForBuild)
        {
            $optionalParams['Build'] = $ForBuild
        }

        Set-BMVariable -Session $script:session -Name $Named -Value $WithValue @optionalParams
    }

    function ThenVariableRemoved
    {
        param(
            [Parameter(Mandatory)]
            [string] $Named,

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

        $actualValue = $Named | Get-BMVariable -Session $script:session @optionalParams -ErrorAction Ignore
        $actualValue | Should -BeNullOrEmpty
    }

    function WhenRemovingVariable
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String] $Named,

            [String] $ForApplication,

            [String] $ForApplicationGroup,

            [String] $ForEnvironment,

            [String] $ForServer,

            [String] $ForServerRole,

            [Object] $ForRelease,

            [Object] $ForBuild,

            [switch] $WhatIf,

            [switch] $SkipResultCheck
        )

        $optionalParams = @{ }

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

        if( $WhatIf )
        {
            $optionalParams['WhatIf'] = $true
        }

        $script:result = $Named | Remove-BMVariable -Session $script:session @optionalParams

        if (-not $SkipResultCheck)
        {
            $script:result | Should -BeNullOrEmpty
        }
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

    It 'should remove global variable when it is empty' {
        GivenVariable 'EmptyGlobalVar' -WithValue ''
        WhenRemovingVariable 'EmptyGlobalVar'
        ThenVariableRemoved 'EmptyGlobalVar'
        ThenNoErrorWritten
    }

    It 'should remove application variable when it is empty' {
        $app = GivenApplication
        GivenVariable -Named 'EmptyAppVar' -WithValue '' -ForApplication $app.Application_Name
        WhenRemovingVariable 'EmptyAppVar' -ForApplication $app.Application_Name
        ThenVariableRemoved 'EmptyAppVar' -ForApplication $app.Application_Name
        ThenNoErrorWritten
    }

    It 'should remove build variable when it is empty' {
        $application = GivenAnApplication -Name 'Remove-BMVariable'
        $pipeline = GivenAPipeline -Named 'Remove-BMVariable' -ForApplication $application
        $release = GivenARelease -Named 'Remove-BMVariable' -ForApplication $application -WithNumber '1.0' -UsingPipeline $pipeline
        $build = GivenABuild -ForRelease $release
        GivenVariable 'EmptyBuildVar' -WithValue '' -ForBuild $build
        WhenRemovingVariable 'EmptyBuildVar' -ForBuild $build
        ThenVariableRemoved 'EmptyBuildVar' -ForBuild $build
        ThenNoErrorWritten
    }

    It 'should ignore variable that does not exist' {
        WhenRemovingVariable 'GlobalVar' -ErrorAction Ignore
        ThenNoErrorWritten
    }

    It 'should ignore variable that does not exist' {
        WhenRemovingVariable 'EnvVar' -ForEnvironment 'HouseCarpenter' -ErrorAction Ignore
        ThenNoErrorWritten
    }

    It 'should encode variable names' {
        $varName = '?V a r&!'
        $entityName = '?E n t i t y&!'
        Mock -CommandName 'Invoke-BMRestMethod' `
             -ModuleName 'BuildMasterAutomation' `
             -MockWith {
                [pscustomobject]@{
                    name = $entityName;
                    parent = 'nope';
                }
             }
        WhenRemovingVariable $varName -ForEnvironment $entityName -SkipResultCheck
        ThenNoErrorWritten
        $expectedName =
            "variables/environment/$([Uri]::EscapeDataString($entityName))/$([Uri]::EscapeDataString($varName))"
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter { $Name -eq $expectedName }
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
        $msg = 'Unable to delete variable "EnvironmentFubar" because environment "EnvThatDoesNotExist" does not exist.'
        ThenError ([regex]::Escape($msg))
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

    It 'should remove release variable' {
        $application = GivenAnApplication -Name 'Remove-BMVariable'
        $pipeline = GivenAPipeline -Named 'Remove-BMVariable' -ForApplication $application
        $release = GivenARelease -Named 'Remove-BMVariable' -ForApplication $application -WithNumber '1.0' -UsingPipeline $pipeline
        GivenVariable 'ReleaseVar' -WithValue 'ReleaseValue' -ForRelease $release
        WhenRemovingVariable 'ReleaseVar' -ForRelease $release
        ThenVariableRemoved 'ReleaseVar' -ForRelease $release
        ThenNoErrorWritten
    }

    It 'should remove build variable' {
        $application = GivenAnApplication -Name 'Remove-BMVariable'
        $pipeline = GivenAPipeline -Named 'Remove-BMVariable' -ForApplication $application
        $release = GivenARelease -Named 'Remove-BMVariable' -ForApplication $application -WithNumber '1.0' -UsingPipeline $pipeline
        $build = GivenABuild -ForRelease $release
        GivenVariable 'BuildVar' -WithValue 'BuildValue' -ForBuild $build
        WhenRemovingVariable 'BuildVar' -ForBuild $build
        ThenVariableRemoved 'BuildVar' -ForBuild $build
        ThenNoErrorWritten
    }

    It 'should support WhatIf' {
        GivenVariable 'WhatIfVar' -WithValue 'WhatIfValue'
        WhenRemovingVariable 'WhatIfVar' -WhatIf
        'WhatIfVar' | Get-BMVariable -Session $script:session -ValueOnly | Should -Be 'WhatIfValue'
        ThenNoErrorWritten
    }
}