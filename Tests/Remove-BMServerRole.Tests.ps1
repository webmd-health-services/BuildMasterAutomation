
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession

function Init
{
    $Global:Error.Clear()
    Get-BMServerRole -Session $session | Remove-BMServerRole -Session $session
}

function GivenRole
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    New-BMServerRole -Session $session -Name $Named
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

function ThenRoleExists
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    Get-BMServerRole -Session $session -Name $Named | Should -Not -BeNullOrEmpty
}

function ThenRoleDoesNotExist
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    Get-BMServerRole -Session $session -Name $Named -ErrorAction Ignore | Should -BeNullOrEmpty
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

    $result = Remove-BMServerRole -Session $session -Name $Named @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'Remove-BMServerRole.when role exists' {
    It ('should remove the role') {
        Init
        GivenRole -Named 'Fubar'
        WhenRemovingRole -Named 'Fubar'
        ThenNoErrorWritten
        ThenRoleDoesNotExist -Named 'Fubar'
    }
}

Describe 'Remove-BMServerRole.when role does not exist' {
    It ('should not write any errors') {
        Init
        WhenRemovingRole -Named 'IDoNotExist'
        ThenNoErrorWritten
        ThenRoleDoesNotExist -Named 'IDoNotExist'
    }
}

Describe 'Remove-BMServerRole.when using -WhatIf' {
    It ('should not remove the role') {
        Init
        GivenRole -Named 'One'
        WhenRemovingRole -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenRoleExists -Named 'One'
    }
}

Describe 'Remove-BMServerRole.when name contains URI-sensitive characters' {
    It ('should create role') {
        Init
        GivenRole -Named 'Fubar - _ . Snafu'
        WhenRemovingRole -Named 'Fubar - _ . Snafu'
        ThenNoErrorWritten
        ThenRoleDoesNotExist -Named 'Fubar - _ . Snafu'
    }
}

