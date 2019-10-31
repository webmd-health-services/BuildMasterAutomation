
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$conn = New-BMTestSession

function Init
{
    param(
    )

    $script:getAppGroups = $null

    Get-BMApplicationGroup -Session $conn | ForEach-Object {
        Invoke-BMNativeApiMethod -Session $conn -Name 'ApplicationGroups_DeleteApplicationGroup' -Parameter @{ ApplicationGroup_Id = $_.ApplicationGroup_Id } -Method Post
    }
}

function GivenApplicationGroup
{
    param(
        [string[]]
        $GroupName
    )

    $GroupName | ForEach-Object {
        Invoke-BMNativeApiMethod -Session $conn -Name 'ApplicationGroups_GetOrCreateApplicationGroup' -Parameter @{ ApplicationGroup_Name = $_ } -Method Post
    }
}

function WhenGettingApplicationGroup
{
    param(
        [String]$Name,
        
        [Switch]$WhatIf
    )

    $Global:Error.Clear()

    $optionalParams = @{ }

    $originalWhatIf = $Global:WhatIfPreference
    if( $WhatIf )
    {
        $Global:WhatIfPreference = $true
    }
    try
    {
        $script:getAppGroups = Get-BMApplicationGroup -Session $conn $Name
    }
    finally
    {
        $Global:WhatIfPreference = $originalWhatIf
    }
}

function ThenShouldNotThrowErrors
{
    param(
    )

    $Global:Error | Should BeNullOrEmpty
}

function ThenShouldReturnApplicationGroup
{
    param(
        [string[]]
        $GroupName
    )
    
    $script:getAppGroups | Should -HaveCount @( $GroupName ).Count
    
    $GroupName | ForEach-Object {
        $script:getAppGroups.ApplicationGroup_Name -contains $_ | Should -BeTrue
    }
}

function ThenShouldNotReturnApplicationGroup
{
    param(
    )
    
    $script:getAppGroups | Should -BeNullOrEmpty
}

Describe 'Get-BMApplicationGroup.when getting all application groups' {
    It 'should get application groups' {
        Init
        GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
        WhenGettingApplicationGroup
        ThenShouldNotThrowErrors
        ThenShouldReturnApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
    }
}

Describe 'Get-BMApplicationGroup.when getting a specific application group' {
    It 'should get that application group' {
        Init
        GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
        WhenGettingApplicationGroup 'BMApplicationGroup2'
        ThenShouldNotThrowErrors
        ThenShouldReturnApplicationGroup 'BMApplicationGroup2'
    }
}

Describe 'Get-BMApplicationGroup.when for application group by wildcard' {
    It 'should get find the application groups' {
        Init
        GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BuildMasterAppGroup3'
        WhenGettingApplicationGroup 'BMApplication*'
        ThenShouldNotThrowErrors
        ThenShouldReturnApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2'
    }
}

Describe 'Get-BMApplicationGroup.when searching for application group that doesn''t exist' {
    It 'should return nothing' {
        Init
        GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
        WhenGettingApplicationGroup 'NonExistentApplicationGroup2'
        ThenShouldNotThrowErrors
        ThenShouldNotReturnApplicationGroup
    }
}

Describe 'Get-BMApplicationGroup.when no application groups exist' {
    It 'should return nothing' {
        Init
        WhenGettingApplicationGroup
        ThenShouldNotThrowErrors
        ThenShouldNotReturnApplicationGroup
    }
}

Describe 'Get-BMApplicationGroup.when WhatIfPreference is true' {
    It 'should return application group' {
        Init
        GivenApplicationGroup 'One'
        WhenGettingApplicationGroup 'One' -WhatIf
        ThenShouldNotThrowErrors
        ThenShouldReturnApplicationGroup 'One'
    }
}
