
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    function GivenApplicationGroup
    {
        param(
            [string[]]
            $GroupName
        )

        $GroupName | ForEach-Object {
            Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_GetOrCreateApplicationGroup' -Parameter @{ ApplicationGroup_Name = $_ } -Method Post
        }
    }

    function WhenGettingApplicationGroup
    {
        param(
            [String]$Name,

            [Switch]$WhatIf
        )

        $Global:Error.Clear()

        $originalWhatIf = $Global:WhatIfPreference
        if( $WhatIf )
        {
            $Global:WhatIfPreference = $true
        }
        try
        {
            $script:getAppGroups = $Name | Get-BMApplicationGroup -Session $script:session
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

        $Global:Error | Should -BeNullOrEmpty
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
}

Describe 'Get-BMApplicationGroup' {
    BeforeEach {
        $script:getAppGroups = $null

        Get-BMApplicationGroup -Session $script:session | ForEach-Object {
            Invoke-BMNativeApiMethod -Session $script:session -Name 'ApplicationGroups_DeleteApplicationGroup' -Parameter @{ ApplicationGroup_Id = $_.ApplicationGroup_Id } -Method Post
        }
    }

    It 'should get application groups' {
        GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
        WhenGettingApplicationGroup
        ThenShouldNotThrowErrors
        ThenShouldReturnApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
    }

    It 'should get specific application group' {
        GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
        WhenGettingApplicationGroup 'BMApplicationGroup2'
        ThenShouldNotThrowErrors
        ThenShouldReturnApplicationGroup 'BMApplicationGroup2'
    }

    It 'should get find application groups by wildcard' {
        GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BuildMasterAppGroup3'
        WhenGettingApplicationGroup 'BMApplication*'
        ThenShouldNotThrowErrors
        ThenShouldReturnApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2'
    }

    It 'should ignore no search results' {
        GivenApplicationGroup 'BMApplicationGroup1', 'BMApplicationGroup2', 'BMApplicationGroup3'
        WhenGettingApplicationGroup 'NonExistentApplicationGroup2*'
        ThenShouldNotThrowErrors
        ThenShouldNotReturnApplicationGroup
    }

    It 'should ignore no application groups' {
        WhenGettingApplicationGroup
        ThenShouldNotThrowErrors
        ThenShouldNotReturnApplicationGroup
    }

    It 'should ignore WhatIf' {
        GivenApplicationGroup 'One'
        WhenGettingApplicationGroup 'One' -WhatIf
        ThenShouldNotThrowErrors
        ThenShouldReturnApplicationGroup 'One'
    }
}
