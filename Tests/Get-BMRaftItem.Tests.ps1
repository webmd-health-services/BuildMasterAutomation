
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:testName = $null
    $script:result = $null

    function GivenApp
    {
        param(
            [String] $Named
        )

        New-BMApplication -Session $script:session -Name "${script:testName} ${Named}"
    }

    function GivenRaft
    {
        param(
            [String] $Named
        )

        Set-BMRaft -Session $script:session -Raft "${script:testName} ${Named}"
    }

    function GivenRaftItem
    {
        param(
            [Parameter(Mandatory)]
            [String] $Named,

            [ValidateSet('Module', 'Script', 'DeploymentPlan', 'Pipeline')]
            [String] $OfType,

            [String] $InRaftNamed,

            [String] $InAppNamed
        )

        if (-not $OfType)
        {
            $OfType = 'Module'
        }

        $raftArg = @{ Raft = 1 }
        if ($InRaftNamed)
        {
            $raftArg = @{ Raft = "${script:testName} ${InRaftNamed}" }
        }

        $appArg = @{}
        if ($InAppNamed)
        {
            $raftArg = @{}
            $appArg['Application'] = "${script:testName} ${InAppNamed}"
        }

        $name = "${script:testName} ${Named}"
        Set-BMRaftItem -Session $script:session @raftArg -TypeCode $OfType -RaftItem $name @appArg -PassThru
    }

    function ThenError
    {
        param(
            [Parameter(Mandatory, ParameterSetName='IsEmpty')]
            [switch] $IsEmpty,

            [Parameter(Mandatory, ParameterSetName='Matches')]
            [String] $MatchesRegex
        )

        if ($IsEmpty)
        {
            $Global:Error | Should -BeNullOrEmpty
        }

        if ($MatchesRegex)
        {
            $Global:Error | Should -Match $MatchesRegex
        }
    }

    function ThenItem
    {
        param(
            [String] $ItemNamed,
            [String] $OfType,
            [String] $InRaftNamed,
            [String] $InAppNamed,
            [switch] $Not,
            [switch] $Returned
        )

        $itemName = "${script:testName} ${ItemNamed}"
        if ($Not)
        {
            $script:result |
                Where-Object 'RaftItem_Name' -EQ $itemName |
                Should -BeNullOrEmpty -Because "should not return item ${ItemNamed} (${itemName})"
            return
        }

        $typeToCodeMap = @{
            Module = 3
            Script = 4
            DeploymentPlan = 6
            Pipeline = 8
        }

        $item = $script:result | Where-Object 'RaftItem_Name' -EQ $itemName
        $item | Should -Not -BeNullOrEmpty -Because "should return item ${ItemNamed} (${itemName})"

        if ($OfType)
        {
            $item.Type | Should -Be $OfType
            $item.RaftItemType_Code | Should -Be $typeToCodeMap[$OfType]
        }

        if ($InRaftNamed)
        {
            $InRaftNamed = "${script:testName} ${InRaftNamed}"
        }
        else
        {
            $InRaftNamed = 'Default'
        }
        $raft = Get-BMRaft -Session $script:session -Raft $InRaftNamed
        $item.Raft_Id | Should -Be $raft.Raft_Id

        if ($InAppNamed)
        {
            $item.Application_Id | Should -Not -BeNullOrEmpty
            $item.Application_Name | Should -Be "${script:testName} ${InAppNamed}"
        }
        else
        {
            $item.Application_Id | Should -BeNullOrEmpty
            $item.Application_Name | Should -BeNullOrEmpty
        }
    }

    function ThenReturned
    {
        param(
            [Parameter(Mandatory, Position=0, ParameterSetName='Count')]
            [int] $Count,

            [Parameter(Mandatory, Position=0, ParameterSetName='Count')]
            [switch] $Items,

            [Parameter(Mandatory, ParameterSetName='Nothing')]
            [switch] $Nothing
        )

        if ($Nothing)
        {
            $script:result | Should -BeNullOrEmpty
        }

        if ($Items)
        {
            $script:result | Should -HaveCount $Count
        }
    }

    function WhenGettingRaftItems
    {
        [CmdletBinding()]
        param(
            [hashtable] $WithArgs,

            [String] $Named,

            [Object] $InAppNamed
        )

        if (-not $WithArgs)
        {
            $WithArgs = @{}
        }

        if ($Named)
        {
            $WithArgs['RaftItem'] =  "${script:testName} ${Named}"
        }

        if ($InAppNamed)
        {
            $WithArgs['Application'] = "${script:testName} ${InAppNamed}"
        }

        $script:result = Get-BMRaftItem -Session $script:session @WithArgs
    }

}

Describe 'Get-BMRaftItem' {
    BeforeEach {
        $script:testName = New-BMTestObjectName
        $Global:Error.Clear()
    }

    It 'returns all raft items' {
        GivenRaft '10'
        GivenRaftItem '11'
        GivenRaftItem '12'
        GivenRaftItem '13' -InRaftNamed '10'
        GivenRaftItem '14' -InRaftNamed '10'
        WhenGettingRaftItems -WithArgs @{}
        ThenItem '11' -Returned
        ThenItem '12' -Returned
        ThenItem '13' -Returned -InRaftNamed '10'
        ThenItem '14' -Returned -InRaftNamed '10'
    }

    It 'returns all items in a specific raft' {
        GivenRaft '20'
        GivenRaftItem '21'
        GivenRaftItem '22.ps1'
        GivenRaftItem '23' -InRaftNamed '20'
        GivenRaftItem '24' -InRaftNamed '20'
        WhenGettingRaftItems -WithArgs @{ Raft = 'Default' }
        ThenItem '21' -Returned
        ThenItem '22.ps1' -Returned
        ThenItem '23' -Not -Returned
        ThenItem '24' -Not -Returned
    }

    It 'returns items of only type <_>' -ForEach @('Module', 'Script', 'DeploymentPlan', 'Pipeline') {
        $typeCode = $_
        GivenRaftItem '30' -OfType Module
        GivenRaftItem '31.ps1' -OfType Script
        GivenRaftItem '32' -OfType DeploymentPlan
        GivenRaftItem '33' -OfType Pipeline
        WhenGettingRaftItems -WithArgs @{ TypeCode = $typeCode }
        ThenItem '30' -Not:($typeCode -ne 'Module') -Returned -OfType Module
        ThenItem '31.ps1' -Not:($typeCode -ne 'Script') -Returned -OfType Script
        ThenItem '32' -Not:($typeCode -ne 'DeploymentPlan') -Returned -OfType DeploymentPlan
        ThenItem '33' -Not:($typeCode -ne 'Pipeline') -Returned -OfType Pipeline
    }

    Context 'item type does not match' {
        It 'writes <_> type code in error message' -ForEach @('Module', 'Script', 'DeploymentPlan', 'Pipeline') {
            $expectedMsg = $typeCodeToSearchFor = $_
            if ($expectedMsg -eq 'DeploymentPlan')
            {
                $expectedMsg = 'Deployment Plan'
            }

            $itemsTypeCode = 'Module'
            if ($itemsTypeCode -eq $typeCodeToSearchFor)
            {
                $itemsTypeCode = 'Pipeline'
            }
            GivenRaftItem '35' -OfType $itemsTypeCode
            WhenGettingRaftItems -Named '35' `
                                 -WithArgs @{ TypeCode = $typeCodeToSearchFor ; ErrorAction = 'SilentlyContinue' }
            ThenReturned -Nothing
            ThenError -Matches "^${expectedMsg} .* does not exist"
        }
    }

    It 'allows finding no items by type' {
        WhenGettingRaftItems -WithArgs @{ TypeCode = 'DeploymentPlan' }
        ThenItem '40' -Not -Returned
        ThenError -IsEmpty
    }

    It 'finds by wildcard' {
        GivenRaftItem '40'
        GivenRaftItem '41'
        GivenRaftItem '42'
        GivenRaftItem '43'
        WhenGettingRaftItems -WithArgs @{ RaftItem = '* 4[12]' }
        ThenItem '40' -Not -Returned
        ThenItem '41' -Returned
        ThenItem '42' -Returned
        ThenItem '43' -Not -Returned
    }

    It 'allows finding no items by wildcard' {
        WhenGettingRaftItems -WithArgs @{ RaftItem = '*donotexistatallevernoway*' }
        ThenReturned -Nothing
        ThenError -IsEmpty
    }

    Context 'getting item by name' {
        Context 'item exists' {
            It 'returns item' {
                GivenRaftItem '50'
                WhenGettingRaftItems -Named '50'
                ThenReturned 1 -Items
                ThenItem '50' -Returned
            }
        }

        Context 'item does not exist' {
            It 'writes an error' {
                WhenGettingRaftItems -Named '60' -ErrorAction SilentlyContinue
                ThenReturned -Nothing
                ThenError -Matches '60" does not exist'
            }
        }
    }

    Context 'getting item by id' {
        Context 'item exists' {
            It 'returns item' {
                $item = GivenRaftItem '70'
                WhenGettingRaftItems -WithArgs @{ RaftItem = $item.RaftItem_Id }
                ThenReturned 1 -Items
                ThenItem '70' -Returned
            }
        }

        Context 'item does not exist' {
            It 'writes an error' {
                WhenGettingRaftItems -WithArgs @{ RaftItem =  5438949 ; ErrorAction = 'SilentlyContinue' }
                ThenReturned -Nothing
                ThenError -Matches '5438949 does not exist'
            }
        }
    }

    Context 'getting item by object' {
        Context 'item exists' {
            It 'returns item' {
                $item = GivenRaftItem '80'
                WhenGettingRaftItems -WithArgs @{ RaftItem = $item }
                ThenReturned 1 -Items
                ThenItem '80' -Returned
            }
        }

        Context 'item does not exist' {
            It 'writes an error' {
                $item = [pscustomobject]@{ RaftItem_Id = 43284234 ; RaftItem_Name = 'donotexistatallevernoway' }
                WhenGettingRaftItems -WithArgs @{ RaftItem = $item } -ErrorAction SilentlyContinue
                ThenReturned -Nothing
                ThenError -Matches '"donotexistatallevernoway" does not exist'
            }
        }
    }

    Context 'piping input' {
        Context 'name' {
            It 'returns item' {
                $item = GivenRaftItem '90'
                $script:result = $item.RaftItem_Name | Get-BMRaftItem -Session $script:session
                ThenReturned 1 -Items
                ThenItem '90' -Returned
            }
        }

        Context 'id' {
            It 'returns item' {
                $item = GivenRaftItem '100'
                $script:result = $item.RAftItem_Id | Get-BMRaftItem -Session $script:session
                ThenReturned 1 -Items
                ThenItem '100' -Returned
            }
        }

        Context 'id' {
            It 'returns item' {
                $script:result = GivenRaftItem '120' | Get-BMRaftItem -Session $script:session
                ThenReturned 1 -Items
                ThenItem '120' -Returned
            }
        }
    }

    Context 'filtering by application' {
        Context 'application exists' {
            It 'returns items using application name' {
                GivenApp '130'
                GivenRaftItem '131'
                GivenRaftItem '132'
                GivenRaftItem '133' -InAppNamed '130'
                GivenRaftItem '134' -InAppNamed '130'
                WhenGettingRaftItems -InAppNamed '130'
                ThenReturned 2 -Items
                ThenItem '133' -Returned -InApp '130'
            }

            It 'returns items using application ID' {
                $app = GivenApp '140'
                GivenRaftItem '141'
                GivenRaftItem '142'
                GivenRaftItem '143' -InAppNamed '140'
                GivenRaftItem '144' -InAppNamed '140'
                WhenGettingRaftItems -WithArgs @{ Application = $app.Application_Id }
                ThenReturned 2 -Items
                ThenItem '143' -Returned -InApp '140'
            }

            It 'returns items using application object' {
                $app = GivenApp '150'
                GivenRaftItem '151'
                GivenRaftItem '152'
                GivenRaftItem '153' -InAppNamed '150'
                GivenRaftItem '154' -InAppNamed '150'
                WhenGettingRaftItems -WithArgs @{ Application = $app }
                ThenReturned 2 -Items
                ThenItem '153' -Returned -InApp '150'
            }
        }

        Context 'application does not exist' {
            Context 'passing application parameter' {
                It 'writes an error' {
                    WhenGettingRaftItems -WithArgs @{
                        RaftItem = '*'
                        Application = 4392432
                        ErrorAction = 'SilentlyContinue'
                    }
                    ThenReturned -Nothing
                    ThenError -Matches 'Application 4392432 does not exist'
                }
            }
        }

        Context 'item does not exist' {
            It 'writes an error' {
                GivenApp '160'
                WhenGettingRaftItems -Named 'idonotexist' `
                                     -InAppNamed '160' `
                                     -WithArgs @{ ErrorAction = 'SilentlyContinue' }
                ThenReturned -Nothing
                ThenError -Matches '^Item.*idonotexist.*in application.*160".*does not exist'
            }
        }
    }

    # writes an error when application-specific item does not exist by name/id
}
