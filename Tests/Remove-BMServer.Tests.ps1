
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    function GivenServer
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        New-BMServer -Session $script:session -Name $Named -Windows
    }

    function ThenServerExists
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        Get-BMServer -Session $script:session -Name $Named | Should -Not -BeNullOrEmpty
    }

    function ThenServerDoesNotExist
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        Get-BMServer -Session $script:session -Name $Named -ErrorAction Ignore | Should -BeNullOrEmpty
    }

    function WhenRemovingServer
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String]$Named,

            [switch] $WhatIf
        )

        $optionalParams = @{ }
        if( $WhatIf )
        {
            $optionalParams['WhatIf'] = $true
        }

        $result = Remove-BMServer -Session $script:session -Name $Named @optionalParams
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Remove-BMServer' {
    BeforeEach {
        $Global:Error.Clear()
        Get-BMServer -Session $script:session | Remove-BMServer -Session $script:session
    }

    It 'should remove the server' {
        GivenServer -Named 'Fubar'
        WhenRemovingServer -Named 'Fubar'
        ThenNoErrorWritten
        ThenServerDoesNotExist -Named 'Fubar'
    }

    It 'should reject when server does not exist' {
        WhenRemovingServer -Named 'IDoNotExist' -ErrorAction SilentlyContinue
        ThenError 'server .* does not exist'
        ThenServerDoesNotExist -Named 'IDoNotExist'
    }

    It 'should support WhatIf' {
        GivenServer -Named 'One'
        WhenRemovingServer -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenServerExists -Named 'One'
    }

    It 'should encode server name' {
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        Mock -CommandName 'Get-BMServer' -ModuleName 'BuildMasterAutomation' -MockWith { [pscustomobject]@{} }
        WhenRemovingServer -Named 'u r i?&'
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter { $Name -eq 'infrastructure/servers/delete/u%20r%20i%3F%26' }
    }
}