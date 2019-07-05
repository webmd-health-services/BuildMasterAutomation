
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession
$result = $null

function GivenApplication
{
    New-BMTestApplication -Session $session -CommandPath $PSCommandPath
}

function GivenApplicationGroup
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    Invoke-BMNativeApiMethod -Session $session -Name 'ApplicationGroups_CreateOrUpdateApplicationGroup' -Method Post -Parameter @{ 'ApplicationGroup_Name' = $Named }
}

function GivenEnvironment
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    New-BMEnvironment -Session $session -Name $Named -ErrorAction Ignore
    Enable-BMEnvironment -Session $session -Name $Named
    Get-BMVariable -Session $session -EnvironmentName $Named | Remove-BMVariable -Session $session -EnvironmentName $Named
}

function GivenServer
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    Get-BMServer -Session $Session -Name $Named -ErrorAction Ignore | Remove-BMServer -Session $Session
    New-BMServer -Session $Session -Name $Named -Local    
}

function GivenServerRole
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    Get-BMServerRole -Session $Session -Name $Named -ErrorAction Ignore | Remove-BMServerRole -Session $Session
    New-BMServerRole -Session $Session -Name $Named
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

    Set-BMVariable -Session $session -Name $Named -Value $WithValue @optionalParams
}

function Init
{
    $Global:Error.Clear()
    $script:result = $null
    Get-BMVariable -Session $session | Remove-BMVariable -Session $session
    # Remove all application groups.
    Invoke-BMNativeApiMethod -Session $session -Name 'ApplicationGroups_GetApplicationGroups' -Method Get |
        ForEach-Object { Invoke-BMNativeApiMethod -Session $session -Name 'ApplicationGroups_DeleteApplicationGroup' -Method Post -Parameter @{ 'ApplicationGroup_Id' = $_.ApplicationGroup_Id } }
}

function ThenVariableSet
{
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Parameter(Mandatory)]
        [string]$To,

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

    $actualValue = Get-BMVariable -Session $session -Name $Named @optionalParams -ValueOnly
    $actualValue | Should -Not -BeNullOrEmpty
    $actualValue | Should -Be $To
}

function WhenSettingVariable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Named,
        [Parameter(Mandatory)]
        [string]$WithValue,
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

    $result = Set-BMVariable -Session $session -Name $Named -Value $WithValue @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'Set-BMVariable.when creating a new a global variable' {
    It 'should create variable' {
        Init
        WhenSettingVariable 'GlobalVar' -WithValue 'GlobalValue'
        ThenVariableSet 'GlobalVar' -To 'GlobalValue'
        ThenNoErrorWritten
    }
}

Describe 'Set-BMVariable.when changing a variable' {
    It 'should create the variable' {
        Init
        GivenVariable 'GlobalVar' -WithValue 'OldValue'
        WhenSettingVariable 'GlobalVar' -WithValue 'NewValue'
        ThenVariableSet 'GlobalVar' -To 'NewValue'
        ThenNoErrorWritten
    }
}

Describe 'Set-BMVariable.when variable name and entity name contain URI-sensitive characters' {
    It 'should create the variable' {
        Init
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        WhenSettingVariable 'E n v i r o n m e n t F u b a r' -WithValue 'Varlue' -ForEnvironment 'Get BMVariable'
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation' -ParameterFilter { $Name -eq 'variables/environment/Get%20BMVariable/E%20n%20v%20i%20r%20o%20n%20m%20e%20n%20t%20F%20u%20b%20a%20r' }
        ThenNoErrorWritten
    }
}

Describe 'Set-BMVariable.when setting an application variable' {
    It 'should create the variable' {
        Init
        $app = GivenApplication
        WhenSettingVariable 'AppFubar' -WithValue 'AppValue' -ForApplication $app.Application_Name
        ThenVariableSet 'AppFubar' -To 'AppValue' -ForApplication $app.Application_Name
        ThenNoErrorWritten
    }
}

Describe 'Set-BMVariable.when setting an application group variable' {
    It 'should create the variable' {
        Init
        GivenApplicationGroup 'fizzbuzz'
        WhenSettingVariable 'AppGroupFubar' -WithValue 'AppGropuValue' -ForApplicationGroup 'fizzbuzz'
        ThenVariableSet 'AppGroupFubar' -To 'AppGropuValue' -ForApplicationGroup 'fizzbuzz'
        ThenNoErrorWritten
    }
}

Describe 'Set-BMVariable.when setting an environment variable' {
    It 'should create the variable' {
        Init
        GivenEnvironment 'SetBMVariable'
        WhenSettingVariable 'EnvironmentFubar' -WithValue 'EnvValue' -ForEnvironment 'SetBMVariable'
        ThenVariableSet 'EnvironmentFubar' -To 'EnvValue' -ForEnvironment 'SetBMVariable'
        ThenNoErrorWritten
    }
}

Describe 'Set-BMVariable.when setting a server variable' {
    It 'should create the variable' {
        Init
        GivenServer 'SetBMVariable'
        WhenSettingVariable 'ServerVar' -WithValue 'ServerValue' -ForServer 'SetBMVariable'
        ThenVariableSet 'ServerVar' -To 'ServerValue' -ForServer 'SetBMVariable'
        ThenNoErrorWritten
    }
}

Describe 'Set-BMVariable.when setting a server role variable' {
    It 'should create the variable' {
        Init
        GivenServerRole 'SetBMVariable'
        WhenSettingVariable 'ServerRoleVar' -WithValue 'ServerRoleValue' -ForServerRole 'SetBMVariable'
        ThenVariableSet 'ServerRoleVar' -To 'ServerRoleValue' -ForServerRole 'SetBMVariable'
        ThenNoErrorWritten
    }
}

Describe 'Set-BMVariable.when setting a variable and WhatIf is true' {
    It 'should not create the variable' {
        Init
        WhenSettingVariable 'GlobalVar' -WithValue 'GlobalValue' -WhatIf
        Get-BMVariable -Session $session -Name 'GlobalVar' -ErrorAction Ignore | Should -BeNullOrEmpty
        ThenNoErrorWritten
    }
}

Describe 'Set-BMVariable.when updating a variable and WhatIf is true' {
    It 'should not create the variable' {
        Init
        GivenVariable 'GlobalVar' -WithValue 'OldValue'
        WhenSettingVariable 'GlobalVar' -WithValue 'NewValue' -WhatIf
        ThenVariableSet 'GlobalVar' -To 'OldValue'
        ThenNoErrorWritten
    }
}