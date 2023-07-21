
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:pipelineName = $defaultName = New-BMTestObjectname
    $script:session = New-BMTestSession
    $script:defaultRaft = Get-BMRaft -Session $script:session -Raft 'Default'
    $script:raft = Set-BMRaft -Session $script:session -Raft $defaultName -PassThru
    $script:app = New-BMApplication -Session $script:session -Name $defaultName -Raft $script:raft
    $script:pipeline = Set-BMPipeline -Session $script:session `
                                      -Name $script:pipelineName `
                                      -Application $script:app `
                                      -Color '#ffffff' `
                                      -PassThru

    function Assert-Release
    {
        param(
            [Parameter(ValueFromPipeline)]
            $Release,

            $HasNumber,

            $HasName,

            $HasPipeline
        )

        begin
        {
            $processedSomething = $false
        }

        process
        {
            $processedSomething = $true

            $Release = $Release | Get-BMRelease -Session $script:session
            $Release | Should -Not -BeNullOrEmpty

            $Release.applicationId | Should -Be $script:app.Application_Id
            $Release.number | Should -Be $HasNumber

            if (-not $HasPipeline)
            {
                 $HasPipeline = $script:pipelineName
            }
            $Release.pipelineName | Should -Be $HasPipeline

            if( -not $HasName )
            {
                $HasName = $HasNumber
            }

            $Release.name | Should -Be $HasName
        }

        end
        {
            $processedSomething | Should -BeTrue
        }
    }

    function GivenRelease
    {
    }

    function New-TestReleaseNumber
    {
        [IO.Path]::GetRandomFileName()
    }

    function WhenSetting
    {
        [CmdletBinding()]
        param(
            [Object] $Release = $script:release,

            [hashtable] $WithArgs = @{}
        )

        Set-BMRelease -Session $script:session -Release $Release @WithArgs

    }
}

Describe 'Set-BMRelease' {
    BeforeEach {
        $Global:Error.Clear()
        $script:release = $null
        $script:releaseNumber = New-TestReleaseNumber
        $script:release = New-BMRelease -Session $script:session `
                                        -Application $script:app `
                                        -Number $script:releaseNumber `
                                        -Pipeline $script:pipeline

    }

    It 'should update release' {
        $newPipeline =
            Set-BMPipeline -Session $script:session -Raft $script:defaultRaft -Name (New-BMTestObjectName) -PassThru
        $updatedRelease = Set-BMRelease -Session $script:session `
                                        -Release $script:release `
                                        -Pipeline $newPipeline `
                                        -Name (New-BMTestObjectName)

        Assert-Release -Release $script:release.id `
                       -HasName $updatedRelease.name `
                       -HasNumber $script:release.number `
                       -HasPipeline "$($script:defaultRaft.Raft_Prefix)::$($newPipeline.RaftItem_Name)"
    }

    It 'should update release with a pipeline from a custom raft' {
        $newPipeline = Set-BMPipeline -Session $script:session -Raft $script:raft -Name (New-BMTestObjectName) -PassThru
        $updatedRelease = Set-BMRelease -Session $script:session `
                                        -Release $script:release `
                                        -Pipeline $newPipeline `
                                        -Name (New-BMTestObjectName)
        Assert-Release -Release $script:release.id `
                       -HasName $updatedRelease.name `
                       -HasNumber $script:release.number `
                       -HasPipeline "$($script:raft.Raft_Prefix)::$($newPipeline.RaftItem_Name)"
    }

    It 'should not change anything' {
        $updatedRelease = Set-BMRelease -Session $script:session -Release $script:release
        Assert-Release -Release $updatedRelease `
                       -HasName $release.name `
                       -HasNumber $release.number `
                       -HasPipeline "$($script:raft.Raft_Prefix)::$($release.pipelineName)"
    }

    It 'should fail when update does not exist' {
        $Global:Error.Clear()
        $updatedRelease = Set-BMRelease -Session $script:session -Release -1 -ErrorAction SilentlyContinue
        $updatedRelease | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'Release\ "-1"\ does\ not\ exist\.'
    }

    It 'should validate pipeline' {
        WhenSetting -WithArgs @{ Pipeline = 'i do not exist' } -ErrorAction SilentlyContinue
        ThenError -MatchesPattern 'Pipeline "i do not exist" does not exist'
    }

    It 'should validate release' {
        WhenSetting -Release 'i do not exist' -ErrorAction SilentlyContinue
        ThenError -MatchesPattern 'Release "i do not exist" does not exist'
    }
}
