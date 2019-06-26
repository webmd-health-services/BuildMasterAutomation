
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession
$roles = $null

function Init
{
    $Global:Error.Clear()
    Get-BMServerRole -Session $session | Remove-BMServerRole -Session $session
    $script:roles = $null
}

function GivenServerRole
{
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    New-BMServerRole -Session $session -Name $Name
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

function ThenNoRolesReturned
{
    $roles | Should -BeNullOrEmpty
}

function ThenRolesReturned
{
    param(
        [Parameter(Mandatory)]
        [string[]]$Named
    )

    $roles | Should -HaveCount $Named.Count
    foreach( $name in $Named )
    {
        $roles | Where-Object { $_.Name -eq $name } | Should -Not -BeNullOrEmpty
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
    $script:roles = Get-BMServerRole -Session $session @optionalParams
}

Describe 'Get-BMServerRole.when given no name' {
    It ('should return all server roles') {
        Init
        GivenServerRole 'One'
        GivenServerRole 'Two'
        WhenGettingRoles
        ThenRolesReturned 'One','Two'
        ThenNoErrorWritten
    }
}

Describe 'Get-BMServerRole.when given name' {
    It ('should return named role') {
        Init
        GivenServerRole 'One'
        GivenServerRole 'Two'
        WhenGettingRoles -Named 'One'
        ThenRolesReturned 'One'
    }
}

Describe 'Get-BMServerRole.when given wildcards' {
    It ('should return only server roles whose name match the wildcard') {
        Init
        GivenServerRole 'One'
        GivenServerRole 'Onf'
        GivenServerRole 'Two'
        WhenGettingRoles -Named 'On*'
        ThenRolesReturned 'One','Onf'
    }
}

Describe 'Get-BMServerRole.when given wildcard that matches no roles' {
    It ('should return nothing and write no errors') {
        Init
        GivenServerRole 'One'
        WhenGettingRoles -Named 'Blah*'
        ThenNoRolesReturned
        ThenNoErrorWritten
    }
}

Describe 'Get-BMServerRole.when given name for a role that doesn''t exist' {
    It ('should return nothing and write an error') {
        Init
        GivenServerRole 'One'
        WhenGettingRoles -Named 'Blah' -ErrorAction SilentlyContinue
        ThenNoRolesReturned
        ThenError 'does\ not\ exist'
    }
}

Describe 'Get-BMServerRole.when ignoring when a role doesn''t exist' {
    It ('should return nothing and write an error') {
        Init
        GivenServerRole 'One'
        WhenGettingRoles -Named 'Blah' -ErrorAction Ignore
        ThenNoRolesReturned
        ThenNoErrorWritten
    }
}
