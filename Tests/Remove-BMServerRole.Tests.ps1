
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    function GivenRole
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        New-BMServerRole -Session $script:session -Name $Named
    }

    function ThenRoleExists
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        $Named | Get-BMServerRole -Session $script:session | Should -Not -BeNullOrEmpty
    }

    function ThenRoleDoesNotExist
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        $Named | Get-BMServerRole -Session $script:session -ErrorAction Ignore | Should -BeNullOrEmpty
    }

    function WhenRemovingRole
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

        $result = $Named | Remove-BMServerRole -Session $script:session  @optionalParams
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Remove-BMServerRole' {
    BeforeEach {
        $Global:Error.Clear()
        Get-BMServerRole -Session $script:session | Remove-BMServerRole -Session $script:session
    }

    It 'should remove role' {
        GivenRole -Named 'Fubar'
        WhenRemovingRole -Named 'Fubar'
        ThenNoErrorWritten
        ThenRoleDoesNotExist -Named 'Fubar'
    }

    It 'should reject missing role' {
        WhenRemovingRole -Named 'IDoNotExist' -ErrorAction SilentlyContinue
        ThenError 'server role .* does not exist'
        ThenRoleDoesNotExist -Named 'IDoNotExist'
    }

    It 'should ignore errors' {
        WhenRemovingRole -Named 'IDoNotExist2' -ErrorAction Ignore
        ThenNoErrorWritten
        ThenRoleDoesNotExist -Named 'IDoNotExist2'
    }

    It 'should support WhatIf' {
        GivenRole -Named 'One'
        WhenRemovingRole -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenRoleExists -Named 'One'
    }

    It 'should encode role name' {
        GivenRole -Named 'Fubar - _ . Snafu'
        WhenRemovingRole -Named 'Fubar - _ . Snafu'
        ThenNoErrorWritten
        ThenRoleDoesNotExist -Named 'Fubar - _ . Snafu'
    }
}

