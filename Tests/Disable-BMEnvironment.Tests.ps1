
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession

function Init
{
    $Global:Error.Clear()
    Get-BMEnvironment -Session $session | Disable-BMEnvironment -Session $session
}

function GivenEnvironment
{
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Switch]$Disabled
    )

    New-BMEnvironment -Session $session -Name $Named -ErrorAction Ignore
    if( $Disabled )
    {
        Disable-BMEnvironment -Session $session -Name $Named
    }
    else
    {
        Enable-BMEnvironment -Session $session -Name $Named
    }
}

function ThenError
{
    param(
        [Parameter(Mandatory)]
        [string]$Matches
    )

    $Global:Error | Should -Match $Matches
}

function ThenNoErrorWritten
{
    $Global:Error | Should -BeNullOrEmpty
}

function ThenEnvironmentEnabled
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    $environment = Get-BMEnvironment -Session $session -Name $Named 
    $environment | Should -Not -BeNullOrEmpty
    $environment.active | Should -BeTrue
}

function ThenEnvironmentDisabled
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    $environment = Get-BMEnvironment -Session $session -Name $Named 
    $environment | Should -Not -BeNullOrEmpty
    $environment.active | Should -BeFalse
}

function WhenDisablingEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Switch]
        $WhatIf
    )

    $optionalParams = @{ }
    if( $WhatIf )
    {
        $optionalParams['WhatIf'] = $true
    }

    $result = Disable-BMEnvironment -Session $session -Name $Named @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'Disable-BMEnvironment.when environment is enabled' {
    It ('should enable the environment') {
        Init
        GivenEnvironment -Named 'Fubar'
        WhenDisablingEnvironment -Named 'Fubar'
        ThenNoErrorWritten
        ThenEnvironmentDisabled -Named 'Fubar'
    }
}

Describe 'Disable-BMEnvironment.when environment is already disabled' {
    It ('should enable the environment') {
        Init
        GivenEnvironment -Named 'Fubar' -Disabled
        Mock -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation' -ParameterFilter { $Name -eq 'Environments_DeleteEnvironment' }
        WhenDisablingEnvironment -Named 'Fubar'
        ThenNoErrorWritten
        Assert-MockCalled -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation' -Times 0
    }
}

Describe 'Disable-BMEnvironment.when environment does not exist' {
    It ('should write errors') {
        Init
        $name = 'IDoNotExist{0}' -f [IO.Path]::GetRandomFileName()
        WhenDisablingEnvironment -Named $name -ErrorAction SilentlyContinue
        ThenError 'does\ not\ exist'
    }
}

Describe 'Disable-BMEnvironment.when using -WhatIf' {
    It ('should not disable the environment') {
        Init
        GivenEnvironment -Named 'One'
        WhenDisablingEnvironment -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenEnvironmentEnabled -Named 'One'
    }
}
