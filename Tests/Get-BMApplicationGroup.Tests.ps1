
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
        Invoke-BMNativeApiMethod -Session $conn -Name 'ApplicationGroups_DeleteApplicationGroup' -Parameter @{ ApplicationGroup_Id = $_.ApplicationGroup_Id }
    }
}

function GivenApplicationGroup
{
    param(
        [string[]]
        $GroupName
    )

    $GroupName | ForEach-Object {
        Invoke-BMNativeApiMethod -Session $conn -Name 'ApplicationGroups_GetOrCreateApplicationGroup' -Parameter @{ ApplicationGroup_Name = $_ }
    }
}

function WhenGettingApplicationGroup
{
    param(
        [String]
        $Name
    )

    $Global:Error.Clear()

    $script:getAppGroups = Get-BMApplicationGroup -Session $conn $Name
}

function ThenShouldNotThrowErrors
{
    param(
    )

    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

function ThenShouldReturnApplicationGroup
{
    param(
        [string[]]
        $GroupName
    )
    
    It ('should return exactly {0} application groups.' -f @( $GroupName ).Count) {
        @( $script:getAppGroups ).Count | Should Be @( $GroupName ).Count
    }
    
    $GroupName | ForEach-Object {
        It ('should return the application group: {0}.' -f $_) {
            $script:getAppGroups.ApplicationGroup_Name -contains $_ | Should Be $true
        }
    }
}

function ThenShouldNotReturnApplicationGroup
{
    param(
    )
    
    It 'should not return any application groups' {
        $script:getAppGroups | Should BeNullOrEmpty
    }
}

Describe 'Get-BMApplicationGroup.when getting all application groups' {
    Init
    GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
    WhenGettingApplicationGroup
    ThenShouldNotThrowErrors
    ThenShouldReturnApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
}

Describe 'Get-BMApplicationGroup.when getting a specific application group' {
    Init
    GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
    WhenGettingApplicationGroup 'BMApplicationGroup2'
    ThenShouldNotThrowErrors
    ThenShouldReturnApplicationGroup 'BMApplicationGroup2'
}

Describe 'Get-BMApplicationGroup.when for application group by wildcard' {
    Init
    GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BuildMasterAppGroup3'
    WhenGettingApplicationGroup 'BMApplication*'
    ThenShouldNotThrowErrors
    ThenShouldReturnApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2'
}

Describe 'Get-BMApplicationGroup.when searching for application group that doesn''t exist' {
    Init
    GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
    WhenGettingApplicationGroup 'NonExistentApplicationGroup2'
    ThenShouldNotThrowErrors
    ThenShouldNotReturnApplicationGroup
}

Describe 'Get-BMApplicationGroup.when no application groups exist' {
    Init
    WhenGettingApplicationGroup
    ThenShouldNotThrowErrors
    ThenShouldNotReturnApplicationGroup
}
