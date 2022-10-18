
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:app = New-BMTestApplication -Session $script:session -CommandPath $PSCommandPath
    $script:pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())
    $script:pipeline = New-BMPipeline -Session $script:session -Name $script:pipelineName -Application $script:app -Color '#ffffff'

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
            $Release.pipelineId | Should -Be $script:pipeline.Pipeline_Id

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

    It 'should create release when piping application ID' {
        $releaseNumber = New-TestReleaseNumber
        $script:app.Application_Id |
            New-BMRelease -Session $script:session -Number $releaseNumber -Pipeline $script:pipeline.Pipeline_Id |
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