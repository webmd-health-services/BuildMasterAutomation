
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

    foreach( $app in $Application )
    {
        $result | Where-Object { $_.Application_Id -eq $app.Application_Id } | Should -Not -BeNullOrEmpty
    }
}

function ThenDoesNotReturnInactiveApplications
{
    param(
        [object[]]
        $Application
    )

    foreach( $app in $Application )
    {
        $result | Where-Object { $_.Application_Id -eq $app.Application_Id } | Should -BeNullOrEmpty
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
        [Switch]$Force,

        [Switch]$WhatIf
    )

    $originalWhatIf = $WhatIfPreference
    if( $WhatIf )
    {
        $WhatIfPreference = $true
    }

    $optionalParams = @{ }
    if( $Force )
    {
        $optionalParams['Force'] = $true
    }

    try
    {
        $script:result = Get-BMApplication -Session $BMTestSession @optionalParams
    }
    finally
    {
        $WhatIfPreference = $originalWhatIf
    }
}

function WhenGettingAnApplication
{
    param(
        $Name
    )

    $script:result = Get-BMApplication -Session $BMTestSession -Name $Name
}

Describe 'Get-BMApplication.when getting all applications' {
    It 'should get active applications' {
        $app1 = GivenAnApplication -Name $PSCommandPath
        $app2 = GivenAnApplication -Name $PSCommandPath
        $app3 = GivenAnApplication -Name $PSCommandPath -ThatIsDisabled

        WhenGettingAllApplications

        ThenReturnsActiveApplications $app1,$app2
        ThenDoesNotReturnInactiveApplications $app3
    }
}

Describe 'Get-BMApplication.when getting all applications including inactive application' {
    It 'should return active and inactive applications' {
        $app1 = GivenAnApplication -Name $PSCommandPath
        $app2 = GivenAnApplication -Name $PSCommandPath
        $app3 = GivenAnApplication -Name $PSCommandPath -ThatIsDisabled

        WhenGettingAllApplications -Force

        ThenReturnsAllApplications $app1,$app2,$app3
    }
}


Describe 'Get-BMApplication.when getting a specific disabled applicationn' {
    It 'should get disabled application' {
        $app = GivenAnApplication -Name $PSCommandPath -ThatIsDisabled

        WhenGettingAnApplication $app.Application_Name

        ThenReturns -Description '' -Application $app
    }
}

Describe 'Get-BMApplication.when user''s WhatIfPreference is true' {
    It 'should return applications' {
        $app1 = GivenAnApplication -Name $PSCommandPath
        $app2 = GivenAnApplication -Name $PSCommandPath
        WhenGettingAllApplications -WhatIf
        ThenReturnsAllApplications $app1,$app2
    }
}