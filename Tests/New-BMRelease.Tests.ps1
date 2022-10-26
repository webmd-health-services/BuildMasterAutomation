
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $defaultObjectName = New-BMTestObjectName
    $raft = Set-BMRaft -Session $script:session -Raft $defaultObjectName -PassThru
    $script:app = New-BMApplication -Session $script:session -Name $defaultObjectName -Raft $raft
    $script:pipeline = Set-BMPipeline -Session $script:session `
                                      -Name $defaultObjectName `
                                      -Application $app `
                                      -Color '#ffffff' `
                                      -PassThru

    function Assert-Release
    {
        param(
            [Parameter(ValueFromPipeline)]
            $Release,

            $HasNumber,

            $HasName
        )

        process
        {
            $Release | Should -Not -BeNullOrEmpty
            $newRelease = $Release | Get-BMRelease -Session $script:session
            $newRelease | Should -Not -BeNullOrEmpty
            $newRelease.id | Should -Be $Release.id
            $Release.applicationId | Should -Be $script:app.Application_Id
            $Release.number | Should -Be $HasNumber
            $Release.pipelineName | Should -Be $pipeline.Pipeline_Name

            if( -not $HasName )
            {
                $HasName = $HasNumber
            }
            $Release.name | Should -Be $HasName
        }
    }

    function New-TestReleaseNumber
    {
        [IO.Path]::GetRandomFileName()
    }
}

Describe 'New-BMRelease' {
    It 'should create release when piping application' {
        $releaseNumber = New-TestReleaseNumber
        $script:app |
            New-BMRelease -Session $script:session -Number $releaseNumber -Pipeline $script:pipeline |
            Assert-Release -HasNumber $releaseNumber
    }

    It 'should create release when piping application name' {
        $releaseNumber = New-TestReleaseNumber
        $script:app.Application_Name |
            New-BMRelease -Session $script:session -Number $releaseNumber -Pipeline $script:pipeline.Pipeline_Name |
            Assert-Release -HasNumber $releaseNumber
    }

    It 'should set release name' {
        $releaseNumber = New-TestReleaseNumber
        $releaseName = New-TestReleaseNumber
        $script:app |
            New-BMRelease -Session $script:session -Number $releaseNumber -Name $releaseName -Pipeline $script:pipeline |
            Assert-Release -HasNumber $releaseNumber -HasName $releaseName
    }
}