
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession
$environments = $null

function Init
{
    $Global:Error.Clear()
    # Disable all existing environments.
    Get-BMEnvironment -Session $session | Disable-BMEnvironment -Session $session
    $script:environments = $null
}

function GivenEnvironment
{
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Switch]$Disabled
    )

    New-BMEnvironment -Session $session -Name $Name -ErrorAction Ignore
    if( $Disabled )
    {
        Disable-BMEnvironment -Session $session -Name $Name
    }
    else
    {
        Enable-BMEnvironment -Session $session -Name $Name
    }
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

function ThenNoEnvironmentsReturned
{
    $environments | Should -BeNullOrEmpty
}

function ThenEnvironmentsReturned
{
    param(
        [Parameter(Mandatory)]
        [string[]]$Named,

        [Switch]$AndInactiveEnvironments
    )

    if( $AndInactiveEnvironments )
    {
        $environments | Should -Not -BeNullOrEmpty
    }
    else
    {
        $environments | Should -HaveCount $Named.Count
    }
    foreach( $name in $Named )
    {
        $environments | Where-Object { $_.Name -eq $name } | Should -Not -BeNullOrEmpty
    }
}

function WhenGettingEnvironments
{
    [CmdletBinding()]
    param(
        [string]$Named,

        [Switch]$Force
    )

    $optionalParams = @{ }
    if( $Named )
    {
        $optionalParams['Name'] = $Named
    }
    if( $Force )
    {
        $optionalParams['Force'] = $true
    }
    $script:environments = Get-BMEnvironment -Session $session @optionalParams
}

Describe 'Get-BMEnvironment.when given no name' {
    It ('should return all active server environments') {
        Init
        GivenEnvironment 'One'
        GivenEnvironment 'Two'
        WhenGettingEnvironments
        ThenEnvironmentsReturned 'One','Two'
        ThenNoErrorWritten
    }
}

Describe 'Get-BMEnvironment.when given no name and using the Force' {
    It ('should return all active and inactive server environments') {
        Init
        GivenEnvironment 'One'
        WhenGettingEnvironments -Force
        ThenEnvironmentsReturned 'One' -AndInactiveEnvironments
        ThenNoErrorWritten
    }
}

Describe 'Get-BMEnvironment.when given name to an active environment' {
    It ('should return named environment') {
        Init
        GivenEnvironment 'One'
        GivenEnvironment 'Two'
        WhenGettingEnvironments -Named 'One'
        ThenEnvironmentsReturned 'One'
    }
}

Describe 'Get-BMEnvironment.when given name to an inactive environment' {
    It ('should return named environment') {
        Init
        GivenEnvironment 'One' -Disabled
        GivenEnvironment 'Two'
        WhenGettingEnvironments -Named 'One'
        ThenEnvironmentsReturned 'One'
    }
}

Describe 'Get-BMEnvironment.when given wildcards' {
    It ('should return only active environments whose name match the wildcard') {
        Init
        GivenEnvironment 'One'
        GivenEnvironment 'Onf'
        GivenEnvironment 'Ong' -Disabled
        GivenEnvironment 'Two'
        WhenGettingEnvironments -Named 'On*'
        ThenEnvironmentsReturned 'One','Onf'
    }
}

Describe 'Get-BMEnvironment.when given wildcards and using the Force' {
    It ('should return active and inactive environments whose name match the wildcard') {
        Init
        GivenEnvironment 'One'
        GivenEnvironment 'Onf'
        GivenEnvironment 'Ong' -Disabled
        GivenEnvironment 'Two'
        WhenGettingEnvironments -Named 'On*'
        ThenEnvironmentsReturned 'One','Onf'
    }
}

Describe 'Get-BMEnvironment.when given wildcard that matches no environments' {
    It ('should return nothing and write no errors') {
        Init
        GivenEnvironment 'One'
        GivenEnvironment 'Blah' -Disabled
        WhenGettingEnvironments -Named 'Blah*'
        ThenNoEnvironmentsReturned
        ThenNoErrorWritten
    }
}

Describe 'Get-BMEnvironment.when given name for an environment that doesn''t exist' {
    It ('should return nothing and write an error') {
        Init
        GivenEnvironment 'One'
        WhenGettingEnvironments -Named ('Blah{0}' -f [IO.Path]::GetRandomFileName()) -ErrorAction SilentlyContinue
        ThenNoEnvironmentsReturned
        ThenError 'does\ not\ exist'
    }
}

Describe 'Get-BMEnvironment.when ignoring when a environment doesn''t exist' {
    It ('should return nothing and write an error') {
        Init
        GivenEnvironment 'One'
        WhenGettingEnvironments -Named ('Blah{0}' -f [IO.Path]::GetRandomFileName()) -ErrorAction Ignore
        ThenNoEnvironmentsReturned
        ThenNoErrorWritten
    }
}
