
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:result = $null

    function GivenServerRole
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

    function WhenCreatingRole
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

        $script:result = New-BMServerRole -Session $script:session -Name $Named @optionalParams
        $script:result | Should -BeNullOrEmpty
    }
}

Describe 'New-BMServerRole' {
    BeforeEach {
        $Global:Error.Clear()
        $script:result = $null
        Get-BMServerRole -Session $script:session | Remove-BMServerRole -Session $script:session
    }

    It 'should create role' {
        WhenCreatingRole -Named 'Fubar'
        ThenNoErrorWritten
        ThenRoleExists -Named 'Fubar'
    }

    It 'should encode URL-sensitive characters' {
        WhenCreatingRole -Named 'Fubar - _ . Snafu'
        ThenNoErrorWritten
        ThenRoleExists -Named 'Fubar - _ . Snafu'
    }

    It 'should reject role that already exists' {
        GivenServerRole -Named 'One'
        WhenCreatingRole -Named 'One' -ErrorAction SilentlyContinue
        ThenError 'already\ exists'
    }

    It 'should ignore errors' {
        GivenServerRole -Named 'One'
        WhenCreatingRole -Named 'One' -ErrorAction Ignore
        ThenNoErrorWritten
    }

    It 'should support WhatIf' {
        WhenCreatingRole -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenRoleDoesNotExist -Named 'One'
    }
}
