
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

function ThenNothingReturned
{
    $result | Should -BeNullOrEmpty
}

function ThenVariableReturned
{
    param(
        [Parameter(Mandatory)]
        [hashtable]$Variable
    )

    $result | Should -Not -BeNullOrEmpty
    [string[]]$expectedVariableName = $Variable.Keys
    $result | Should -HaveCount $expectedVariableName.Count
    foreach( $variableName in $expectedVariableName )
    {
        $actualVariable = $result | Where-Object { $_.Name -eq $variableName } 
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

    $result | Should -Not -BeNullOrEmpty
    $result | Should -HaveCount $Value.Count
    $result | Should -Be $Value
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

    $script:result = Get-BMVariable -Session $session @optionalParams
}

Describe 'Get-BMVariable.when there are no global variables' {
    It 'should return nothing' {
        Init
        WhenGettingVariable
        ThenNothingReturned
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting a global variable' {
    It 'should return the variable' {
        Init
        GivenVariable 'Fubar' -WithValue 'Snafu'
        GivenVariable 'Snafu' -WithValue 'Fubar'
        WhenGettingVariable 'Fubar'
        ThenVariableReturned @{ 'Fubar' = 'Snafu' }
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting a variable that doesn''t exist' {
    It 'should fail' {
        Init
        WhenGettingVariable 'IDONOTEXIST!!!!!!' -ErrorAction SilentlyContinue
        ThenNothingReturned
        ThenError 'does\ not\ exist'
    }
}

Describe 'Get-BMVariable.when ignoring when a variable that doesn''t exist' {
    It 'should write no errors' {
        Init
        WhenGettingVariable 'IDONOTEXIST!!!!!!' -ErrorAction Ignore
        ThenNothingReturned
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting a variable that doesn''t exist using wildcards' {
    It 'should fail' {
        Init
        WhenGettingVariable 'IDONOTEXIST*'
        ThenNothingReturned
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting all global variables' {
    It 'should return all variables' {
        Init
        GivenVariable 'Fubar' -WithValue 'Snafu'
        GivenVariable 'Snafu' -WithValue 'Fubar'
        WhenGettingVariable
        ThenVariableReturned @{ 'Fubar' = 'Snafu'; 'Snafu' = 'Fubar' }
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting all global variable values' {
    It 'should return all values' {
        Init
        GivenVariable 'Fubar' -WithValue 'Snafu'
        GivenVariable 'Snafu' -WithValue 'Fubar'
        WhenGettingVariable -ValueOnly
        ThenVariableValuesReturned @( 'Snafu', 'Fubar' )
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting global variable''s value' {
    It 'should return just the variable''s value' {
        Init
        GivenVariable 'Fubar' -WithValue 'Snafu'
        GivenVariable 'Snafu' -WithValue 'Fubar'
        WhenGettingVariable 'Snafu' -ValueOnly
        ThenVariableValuesReturned 'Fubar'
    }
}

Describe 'Get-BMVariable.when getting an application''s variables' {
    It 'should return the variable' {
        Init
        $app = GivenApplication
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'AppFubar' -WithValue 'Snafu' -ForApplication $app.Application_Name
        WhenGettingVariable 'AppFubar' -ForApplication $app.Application_Name
        ThenVariableReturned @{ 'AppFubar' = 'Snafu' }
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting an application variable and WhatIf is true' {
    It 'should get the variable' {
        Init
        $app = GivenApplication
        GivenVariable 'AppFubar' -WithValue 'Snafu' -ForApplication $app.Application_Name
        $WhatIfPreference = $true
        WhenGettingVariable 'AppFubar' -ForApplication $app.Application_Name
        $WhatIfPreference | Should -BeTrue
        $WhatIfPreference = $false
        ThenVariableReturned @{ 'AppFubar' = 'Snafu' }
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting an application group''s variables' {
    It 'should return the variable' {
        Init
        GivenApplicationGroup 'fizzbuzz'
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'AppGroupFubar' -WithValue 'Snafu' -ForApplicationGroup 'fizzbuzz'
        WhenGettingVariable 'AppGroupFubar' -ForApplicationGroup 'fizzbuzz'
        ThenVariableReturned @{ 'AppGroupFubar' = 'Snafu' }
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting an application group variable and WhatIf is true' {
    It 'should get the variable' {
        Init
        $app = GivenApplicationGroup 'fizzbuzz'
        GivenVariable 'AppGroupFubar' -WithValue 'Snafu' -ForApplicationGroup 'fizzbuzz'
        $WhatIfPreference = $true
        WhenGettingVariable 'AppGroupFubar' -ForApplicationGroup 'fizzbuzz'
        $WhatIfPreference | Should -BeTrue
        $WhatIfPreference = $false
        ThenVariableReturned @{ 'AppGroupFubar' = 'Snafu' }
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting an environment''s variables' {
    It 'should return the variable' {
        Init
        GivenEnvironment 'GetBMVariable'
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'EnvironmentFubar' -WithValue 'Snafu' -ForEnvironment 'GetBMVariable'
        WhenGettingVariable 'EnvironmentFubar' -ForEnvironment 'GetBMVariable'
        ThenVariableReturned @{ 'EnvironmentFubar' = 'Snafu' }
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting a server variable' {
    It 'should return the variable' {
        Init
        GivenServer 'GetBMVariable'
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'ServerVar' -WithValue 'ServerValue' -ForServer 'GetBMVariable'
        WhenGettingVariable 'ServerVar' -ForServer 'GetBMVariable'
        ThenVariableReturned @{ 'ServerVar' = 'ServerValue' }
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when getting a server role variable' {
    It 'should return the variable' {
        Init
        GivenServerRole 'GetBMVariable'
        GivenVariable 'GlobalVar' -WithValue 'GlobalSnafu'
        GivenVariable 'ServerRoleVar' -WithValue 'ServerRoleValue' -ForServerRole 'GetBMVariable'
        WhenGettingVariable 'ServerRoleVar' -ForServerRole 'GetBMVariable'
        ThenVariableReturned @{ 'ServerRoleVar' = 'ServerRoleValue' }
        ThenNoErrorWritten
    }
}

Describe 'Get-BMVariable.when entity name contains URI-sensitive characters' {
    It 'should return the variable' {
        Init
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        WhenGettingVariable 'EnvironmentFubar' -ForEnvironment 'Get BMVariable'
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation' -ParameterFilter { $Name -eq 'variables/environment/Get%20BMVariable' }
        ThenNoErrorWritten
    }
}
