
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    function GivenRaft
    {
        param(
            [Parameter(Mandatory)]
            [String] $Named,

            [switch] $PassThru
        )

        $raft = $null
        $Named | Set-BMRaft -Session $script:session -PassThru:$PassThru | Tee-Object -Variable 'raft'

        if ($PassThru)
        {
            $raft | Should -Not -BeNullOrEmpty
        }
    }

    function ThenReturned
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ParameterSetName='ByCount')]
            [int] $Count,

            [Parameter(Mandatory, ParameterSetName='ByName')]
            [String] $RaftNamed,

            [Parameter(ParameterSetName='ByName')]
            [String] $WithPrefix
        )

        if ($PSCmdlet.ParameterSetName -eq 'ByCount')
        {
            $script:results | Should -HaveCount $Count
            return
        }

        $script:results | Should -Not -BeNullOrEmpty
        $script:results | Where-Object 'Raft_Name' -EQ $RaftNamed | Should -Not -BeNullOrEmpty
        if ($PSBoundParameters.ContainsKey('WithPrefix'))
        {
            $script:results | Where-Object 'Raft_Prefix' -EQ $WithPrefix | Should -Not -BeNullOrEmpty
        }
    }

    function WhenGettingRafts
    {
        [CmdletBinding()]
        param(
            [hashtable] $WithArgs = @{}
        )

        $script:results = Get-BMRaft -Session $script:session @WithArgs
    }
}

Describe 'Get-BMRaft' {
    BeforeEach {
        Get-BMRaft -Session $script:session |
            Where-Object 'Raft_Name' -NE 'Default' |
            Remove-BMRaft -Session $script:session
        Get-BMRaft -Session $script:session | Should -HaveCount 1
        $Global:Error.Clear()
    }

    It 'should get all rafts' {
        GivenRaft 'all rafts'
        WhenGettingRafts
        ThenReturned -Count 2
        ThenReturned -RaftNamed 'Default' -WithPrefix 'global'
        ThenReturned -RaftNamed 'all rafts' -WithPrefix 'all rafts'
    }

    It 'should get raft by name' {
        GivenRaft 'named raft'
        WhenGettingRafts -WithArgs @{ 'Raft' = 'named raft' }
        ThenReturned -Count 1
        ThenReturned -RaftNamed 'named raft'
    }

    It 'should get raft by wildcard' {
        GivenRaft 'wildcard raft'
        WhenGettingRafts -WithArgs @{ 'Raft' = 'wildcard*' }
        ThenReturned -Count 1
        ThenReturned -RaftNamed 'wildcard raft'
    }

    It 'should write error for non-existent raft <_> ' -TestCases @('i do not exist', 9009) {
        WhenGettingRafts -WithArgs @{ 'Raft' = $_ } -ErrorAction SilentlyContinue
        ThenREturned -Count 0
        ThenError ([regex]::Escape('does not exist'))
    }

    It 'should ignore errors for non-existent raft <_>' -TestCases @('i do not exist', 9009) {
        WhenGettingRafts -WithArgs @{ 'Raft' = $_ ; ErrorAction = 'Ignore' }
        ThenReturned -Count 0
        ThenError -IsEmpty
    }

    It 'should get raft by id' {
        $raft = GivenRaft 'id raft' -PassThru
        WhenGettingRafts -WithArgs @{ 'Raft' = $raft.Raft_Id }
        ThenReturned -Count 1
        ThenReturned -RaftNamed 'id raft'
    }

    It 'should ignore whatif' {
        GivenRaft 'whatif raft'
        $WhatIfPreference = $true
        WhenGettingRafts -WithArgs @{ 'Raft' = 'whatif raft' }
        ThenReturned -Count 1
        ThenReturned -RaftNamed 'whatif raft'
        ThenError -IsEmpty
    }
}