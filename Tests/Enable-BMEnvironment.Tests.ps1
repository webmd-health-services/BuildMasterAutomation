
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

function WhenEnablingEnvironment
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

    $result = Enable-BMEnvironment -Session $session -Name $Named @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'Enable-BMEnvironment.when environment is disabled' {
    It ('should enable the environment') {
        Init
        GivenEnvironment -Named 'Fubar' -Disabled
        WhenEnablingEnvironment -Named 'Fubar'
        ThenNoErrorWritten
        ThenEnvironmentEnabled -Named 'Fubar'
    }
}

Describe 'Enable-BMEnvironment.when environment is already enabled' {
    It ('should enable the environment') {
        Init
        GivenEnvironment -Named 'Fubar'
        Mock -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation' -ParameterFilter { $Name -eq 'Environments_UndeleteEnvironment' }
        WhenEnablingEnvironment -Named 'Fubar'
        ThenNoErrorWritten
        Assert-MockCalled -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation' -Times 0
    }
}

Describe 'Enable-BMEnvironment.when environment does not exist' {
    It ('should write errors') {
        Init
        $name = 'IDoNotExist{0}' -f [IO.Path]::GetRandomFileName()
        WhenEnablingEnvironment -Named $name -ErrorAction SilentlyContinue
        ThenError 'does\ not\ exist'
    }
}

Describe 'Enable-BMEnvironment.when using -WhatIf' {
    It ('should not enable the environment') {
        Init
        GivenEnvironment -Named 'One' -Disabled
        WhenEnablingEnvironment -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenEnvironmentDisabled -Named 'One'
    }
}
