
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    function Init
    {
        $Global:Error.Clear()
        Get-BMEnvironment -Session $script:session | Disable-BMEnvironment -Session $script:session
    }

    function GivenEnvironment
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named,

            [Switch]$Disabled
        )

        New-BMEnvironment -Session $script:session -Name $Named -ErrorAction Ignore
        if( $Disabled )
        {
            $Named | Disable-BMEnvironment -Session $script:session
        }
        else
        {
            $Named | Enable-BMEnvironment -Session $script:session
        }
    }

    function ThenEnvironmentEnabled
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        $environment = $Named | Get-BMEnvironment -Session $script:session
        $environment | Should -Not -BeNullOrEmpty
        $environment.active | Should -BeTrue
    }

    function ThenEnvironmentDisabled
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        $environment = $Named | Get-BMEnvironment -Session $script:session
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

        $result = $Named | Disable-BMEnvironment -Session $script:session @optionalParams
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Disable-BMEnvironment' {
    It 'should disable the environment' {
        Init
        GivenEnvironment -Named 'Fubar'
        WhenDisablingEnvironment -Named 'Fubar'
        ThenNoErrorWritten
        ThenEnvironmentDisabled -Named 'Fubar'
    }

    It 'should not disable a disabled environment' {
        Init
        GivenEnvironment -Named 'Fubar' -Disabled
        Mock -CommandName 'Invoke-BMNativeApiMethod' `
             -ModuleName 'BuildMasterAutomation' `
             -ParameterFilter { $Name -eq 'Environments_DeleteEnvironment' }
        WhenDisablingEnvironment -Named 'Fubar'
        ThenNoErrorWritten
        Assert-MockCalled -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation' -Times 0
    }

    It 'should write errors' {
        Init
        $name = 'IDoNotExist{0}' -f [IO.Path]::GetRandomFileName()
        WhenDisablingEnvironment -Named $name -ErrorAction SilentlyContinue
        ThenError 'does\ not\ exist'
    }

    It 'should not disable the environment' {
        Init
        GivenEnvironment -Named 'One'
        WhenDisablingEnvironment -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenEnvironmentEnabled -Named 'One'
    }
}