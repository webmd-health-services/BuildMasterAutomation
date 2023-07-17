
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:pipelineName = $defaultName = New-BMTestObjectname
    $script:session = New-BMTestSession
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

            $Release | Should -Not -BeNullOrEmpty
            $newRelease = $Release | Get-BMRelease -Session $script:session
            $newRelease | Should -Not -BeNullOrEmpty
            $newRelease.id | Should -Be $Release.id
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
        $releaseNumber = New-TestReleaseNumber
        $script:release = New-BMRelease -Session $script:session `
                                        -Application $script:app `
                                        -Number $releaseNumber `
                                        -Pipeline $script:pipeline
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
    }

    It 'should update release' {
        GivenRelease
        $newPipeline = Set-BMPipeline -Session $script:session -Raft $script:raft -Name 'updating a release' -PassThru
        $updatedRelease = Set-BMRelease -Session $script:session `
                                        -Release $script:release `
                                        -Pipeline $newPipeline `
                                        -Name 'new name'
        Assert-Release -Release $updatedRelease `
                       -HasName 'new name' `
                       -HasNumber $script:release.number `
                       -HasPipeline 'updating a release'
    }

    It 'should not change anything' {
        $releaseNumber = New-TestReleaseNumber
        $release = New-BMRelease -Session $script:session -Application $script:app -Number $releaseNumber -Pipeline $script:pipeline
        $updatedRelease = Set-BMRelease -Session $script:session -Release $release
        Assert-Release -Release $updatedRelease `
                       -HasName $release.name `
                       -HasNumber $release.number `
                       -HasPipeline $release.pipelineName
    }

    It 'should fail when update does not exist' {
        $Global:Error.Clear()
        $updatedRelease = Set-BMRelease -Session $script:session -Release -1 -ErrorAction SilentlyContinue
        $updatedRelease | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'Release\ "-1"\ does\ not\ exist\.'
    }

    It 'should validate pipeline' {
        GivenRelease
        WhenSetting -WithArgs @{ Pipeline = 'i do not exist' } -ErrorAction SilentlyContinue
        ThenError -MatchesPattern 'Pipeline "i do not exist" does not exist'
    }

    It 'should validate release' {
        WhenSetting -Release 'i do not exist' -ErrorAction SilentlyContinue
        ThenError -MatchesPattern 'Release "i do not exist" does not exist'
    }
}
