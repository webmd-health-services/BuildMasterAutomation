
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

[object[]]$result = $null

function ThenReturns
{
    param(
        $Description,
        $Application
    )

    It ('should return {0} applications' -f $Description) {
        foreach( $app in $Application )
        {
            $result | Where-Object { $_.Application_Id -eq $app.Application_Id } | Should -Not -BeNullOrEmpty
        }
    }
}

function ThenDoesNotReturnInactiveApplications
{
    param(
        [object[]]
        $Application
    )

    It ('should not return inactive applications') {
        foreach( $app in $Application )
        {
            $result | Where-Object { $_.Application_Id -eq $app.Application_Id } | Should -BeNullOrEmpty
        }
    }
}

function ThenReturnsActiveApplications
{
    param(
        [object[]]
        $Application
    )

    ThenReturns -Description 'all active' -Application $Application
}

function ThenReturnsAllApplications
{
    param(
        [object[]]
        $Application
    )

    ThenReturns -Description 'all' -Application $Application
}

function WhenGettingAllApplications
{
    param(
        [Switch]
        $Force
    )

    $script:result = Get-BMApplication -Session $BMTestSession @PSBoundParameters
}

function WhenGettingAnApplication
{
    param(
        $Name
    )

    $script:result = Get-BMApplication -Session $BMTestSession -Name $Name
}

Describe 'Get-BMApplication.when getting all applications' {
    $app1 = GivenAnApplication -Name $PSCommandPath
    $app2 = GivenAnApplication -Name $PSCommandPath
    $app3 = GivenAnApplication -Name $PSCommandPath -ThatIsDisabled

    WhenGettingAllApplications

    ThenReturnsActiveApplications $app1,$app2
    ThenDoesNotReturnInactiveApplications $app3
}

Describe 'Get-BMApplication.when getting all applications including inactive application' {
    $app1 = GivenAnApplication -Name $PSCommandPath
    $app2 = GivenAnApplication -Name $PSCommandPath
    $app3 = GivenAnApplication -Name $PSCommandPath -ThatIsDisabled

    WhenGettingAllApplications -Force

    ThenReturnsAllApplications $app1,$app2,$app3
}


Describe 'Get-BMApplication.when getting a specific disabled applicationn' {
    $app = GivenAnApplication -Name $PSCommandPath -ThatIsDisabled

    WhenGettingAnApplication $app.Application_Name

    ThenReturns -Description '' -Application $app
}