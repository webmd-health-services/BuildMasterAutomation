
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
            Disable-BMEnvironment -Session $script:session -Name $Named
        }
        else
        {
            Enable-BMEnvironment -Session $script:session -Name $Named
        }
    }

    function ThenEnvironmentEnabled
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        $environment = Get-BMEnvironment -Session $script:session -Name $Named
        $environment | Should -Not -BeNullOrEmpty
        $environment.active | Should -BeTrue
    }

    function ThenEnvironmentDisabled
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        $environment = Get-BMEnvironment -Session $script:session -Name $Named
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

        $result = Enable-BMEnvironment -Session $script:session -Name $Named @optionalParams
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Enable-BMEnvironment' {
    It ('should enable the environment') {
        Init
        GivenEnvironment -Named 'Fubar' -Disabled
        WhenEnablingEnvironment -Named 'Fubar'
        ThenNoErrorWritten
        ThenEnvironmentEnabled -Named 'Fubar'
    }

    It ('should enable the environment') {
        Init
        GivenEnvironment -Named 'Fubar'
        Mock -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation' -ParameterFilter { $Name -eq 'Environments_UndeleteEnvironment' }
        WhenEnablingEnvironment -Named 'Fubar'
        ThenNoErrorWritten
        Assert-MockCalled -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation' -Times 0
    }

    It ('should write errors') {
        Init
        $name = 'IDoNotExist{0}' -f [IO.Path]::GetRandomFileName()
        WhenEnablingEnvironment -Named $name -ErrorAction SilentlyContinue
        ThenError 'does\ not\ exist'
    }

    It ('should not enable the environment') {
        Init
        GivenEnvironment -Named 'One' -Disabled
        WhenEnablingEnvironment -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenEnvironmentDisabled -Named 'One'
    }
}
