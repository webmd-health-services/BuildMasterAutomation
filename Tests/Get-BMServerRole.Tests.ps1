
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:roles = $null

    function GivenServerRole
    {
        param(
            [Parameter(Mandatory)]
            [string]$Name
        )

        New-BMServerRole -Session $script:session -Name $Name
    }

    function ThenNoRolesReturned
    {
        $script:roles | Should -BeNullOrEmpty
    }

    function ThenRolesReturned
    {
        param(
            [Parameter(Mandatory)]
            [string[]]$Named
        )

        $script:roles | Should -HaveCount $Named.Count
        foreach( $name in $Named )
        {
            $script:roles | Where-Object { $_.Name -eq $name } | Should -Not -BeNullOrEmpty
        }
    }

    function WhenGettingRoles
    {
        [CmdletBinding()]
        param(
            [string]$Named
        )

        $optionalParams = @{ }
        if( $Named )
        {
            $optionalParams['Name'] = $Named
        }
        $script:roles = Get-BMServerRole -Session $script:session @optionalParams
    }
}

Describe 'Get-BMServerRole' {
    BeforeEach {
        $Global:Error.Clear()
        Get-BMServerRole -Session $script:session | Remove-BMServerRole -Session $script:session
        $script:roles = $null
    }

    It 'should return all server roles' {
        GivenServerRole 'One'
        GivenServerRole 'Two'
        WhenGettingRoles
        ThenRolesReturned 'One','Two'
        ThenNoErrorWritten
    }

    It 'should return named role' {
        GivenServerRole 'One'
        GivenServerRole 'Two'
        WhenGettingRoles -Named 'One'
        ThenRolesReturned 'One'
    }

    It 'should search by wildcard' {
        GivenServerRole 'One'
        GivenServerRole 'Onf'
        GivenServerRole 'Two'
        WhenGettingRoles -Named 'On*'
        ThenRolesReturned 'One','Onf'
    }

    It 'should return nothing and write no errors when wildcard matches no roles' {
        GivenServerRole 'One'
        WhenGettingRoles -Named 'Blah*'
        ThenNoRolesReturned
        ThenNoErrorWritten
    }

    It 'should return nothing and write an error' {
        GivenServerRole 'One'
        WhenGettingRoles -Named 'Blah' -ErrorAction SilentlyContinue
        ThenNoRolesReturned
        ThenError 'does\ not\ exist'
    }

    It 'should ignore errors' {
        GivenServerRole 'One'
        WhenGettingRoles -Named 'Blah' -ErrorAction Ignore
        ThenNoRolesReturned
        ThenNoErrorWritten
    }
}
