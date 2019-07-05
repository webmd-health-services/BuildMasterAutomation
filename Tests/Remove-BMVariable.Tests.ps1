
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

    $actualValue = Get-BMVariable -Session $session -Name $Named @optionalParams -ErrorAction Ignore
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

    $result = Remove-BMVariable -Session $session -Name $Named @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'Remove-BMVariable.when removing a global variable' {
    It 'should remove the variable' {
        Init
        GivenVariable 'GlobalVar' -WithValue 'GlobalValue'
        WhenRemovingVariable 'GlobalVar'
        ThenVariableRemoved 'GlobalVar'
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when removing a variable that doesn''t exist' {
    It 'should remove the variable' {
        Init
        WhenRemovingVariable 'GlobalVar'
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when ignoring when entity doesn''t exist' {
    It 'should remove the variable' {
        Init
        WhenRemovingVariable 'EnvVar' -ForEnvironment 'HouseCarpenter' -ErrorAction Ignore
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when variable name and entity name contain URI-sensitive characters' {
    It 'should remove the variable' {
        Init
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        WhenRemovingVariable '?V a r&' -ForEnvironment '?E n v&'
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation' -ParameterFilter { $Name -eq 'variables/environment/%3FE%20n%20v%26/%3FV%20a%20r%26' }
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when removing an application variable' {
    It 'should write an error' {
        Init
        $app = GivenApplication
        GivenVariable -Named 'AppFubar' -WithValue 'AppValue' -ForApplication $app.Application_Name
        WhenRemovingVariable 'AppFubar' -ForApplication $app.Application_Name
        ThenVariableRemoved 'AppFubar' -ForApplication $app.Application_Name
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when removing variable from an application that doesn''t exist' {
    It 'should write an error' {
        Init
        WhenRemovingVariable 'AppFubar' -ForApplication 'ItIsHardTimes' -ErrorAction SilentlyContinue
        ThenError 'does\ not\ exist'
    }
}

Describe 'Remove-BMVariable.when ignoring when an application doesn''t exist' {
    It 'should remove the variable' {
        Init
        WhenRemovingVariable 'AppFubar' -ForApplication 'ItIsHardTimes' -ErrorAction Ignore
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when removing an application group variable' {
    It 'should remove the variable' {
        Init
        GivenApplicationGroup 'fizzbuzz'
        GivenVariable -Named 'AppGroupFubar' -WithValue 'AppGropuValue' -ForApplicationGroup 'fizzbuzz'
        WhenRemovingVariable 'AppGroupFubar' -ForApplicationGroup 'fizzbuzz'
        ThenVariableRemoved 'AppGroupFubar' -ForApplicationGroup 'fizzbuzz'
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when removing a variable from an application group that doesn''t exist' {
    It 'should write an error' {
        Init
        WhenRemovingVariable 'AppGroupFubar' -ForApplicationGroup 'SmogInCalifornia' -ErrorAction SilentlyContinue
        ThenError 'does\ not\ exist'
    }
}

Describe 'Remove-BMVariable.when ignoring when an application group doesn''t exist' {
    It 'should write an error' {
        Init
        WhenRemovingVariable 'AppGroupFubar' -ForApplicationGroup 'SmogInCalifornia' -ErrorAction Ignore
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when removing an environment variable' {
    It 'should remove the variable' {
        Init
        GivenEnvironment 'RemoveBMVariable'
        GivenVariable -Named 'EnvironmentFubar' -WithValue 'EnvValue' -ForEnvironment 'RemoveBMVariable'
        WhenRemovingVariable 'EnvironmentFubar' -ForEnvironment 'RemoveBMVariable'
        ThenVariableRemoved 'EnvironmentFubar' -ForEnvironment 'RemoveBMVariable'
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when environment doesn''t exist' {
    It 'should write an error' {
        Init
        WhenRemovingVariable 'EnvironmentFubar' -ForEnvironment 'EnvThatDoesNotExist' -ErrorAction SilentlyContinue
        ThenError 'specified environment was not found'
    }
}

Describe 'Remove-BMVariable.when removing a server variable' {
    It 'should remove the variable' {
        Init
        GivenServer 'RemoveBMVariable'
        GivenVariable -Named 'ServerVar' -WithValue 'ServerValue' -ForServer 'RemoveBMVariable'
        WhenRemovingVariable 'ServerVar' -ForServer 'RemoveBMVariable'
        ThenVariableRemoved 'ServerVar' -ForServer 'RemoveBMVariable'
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when removing a server role variable' {
    It 'should remove the variable' {
        Init
        GivenServerRole 'RemoveBMVariable'
        GivenVariable -Named 'ServerRoleVar' -WithValue 'ServerRoleValue' -ForServerRole 'RemoveBMVariable'
        WhenRemovingVariable 'ServerRoleVar' -ForServerRole 'RemoveBMVariable'
        ThenVariableRemoved 'ServerRoleVar' -ForServerRole 'RemoveBMVariable'
        ThenNoErrorWritten
    }
}

Describe 'Remove-BMVariable.when WhatIf is true' {
    It 'should not remove the variable' {
        Init
        GivenVariable 'WhatIfVar' -WithValue 'WhatIfValue'
        WhenRemovingVariable 'WhatIfVar' -WhatIf
        Get-BMVariable -Session $session -Name 'WhatIfVar' -ValueOnly | Should -Be 'WhatIfValue'
        ThenNoErrorWritten
    }
}