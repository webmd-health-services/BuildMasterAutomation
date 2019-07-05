
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession
$result = $null

function Init
{
    $Global:Error.Clear()
    $script:result = $null
    Get-BMServerRole -Session $session | Remove-BMServerRole -Session $session
}

function GivenServerRole
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    New-BMServerRole -Session $session -Name $Named
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

    $script:result = New-BMServerRole -Session $session -Name $Named @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'New-BMServerRole' {
    It ('should create role') {
        Init
        WhenCreatingRole -Named 'Fubar'
        ThenNoErrorWritten
        ThenRoleExists -Named 'Fubar'
    }
}

Describe 'New-BMServerRole.when name contains URI-sensitive characters' {
    It ('should create role') {
        Init
        WhenCreatingRole -Named 'Fubar - _ . Snafu'
        ThenNoErrorWritten
        ThenRoleExists -Named 'Fubar - _ . Snafu'
    }
}

Describe 'New-BMServerRole.when role already exists' {
    It ('should write an error') {
        Init
        GivenServerRole -Named 'One'
        WhenCreatingRole -Named 'One' -ErrorAction SilentlyContinue
        ThenError 'already\ exists'
    }
}

Describe 'New-BMServerRole.when ignoring when a role already exists' {
    It ('should not write any errors or return anything') {
        Init
        GivenServerRole -Named 'One'
        WhenCreatingRole -Named 'One' -ErrorAction Ignore
        ThenNoErrorWritten
    }
}

Describe 'New-BMServerRole.when using -WhatIf' {
    It ('should not create the role') {
        Init
        WhenCreatingRole -Named 'One' -WhatIf
        ThenNoErrorWritten
        ThenRoleDoesNotExist -Named 'One'
    }
}
