
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:app = New-BMTestApplication -Session $script:session -CommandPath $PSCommandPath
    $script:pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())
    $script:pipeline =
        New-BMPipeline -Session $script:session -Name $script:pipelineName -Application $script:app -Color '#ffffff'

    function Assert-Release
    {
        param(
            [Parameter(ValueFromPipeline)]
            $Release,

            $HasNumber,

            $HasName,

            $HasPipelineID
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

            if( -not $HasPipelineID )
            {
                $HasPipelineID = $script:pipeline.Pipeline_Id
            }
            $Release.pipelineId | Should -Be $HasPipelineID

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

    function New-TestReleaseNumber
    {
        [IO.Path]::GetRandomFileName()
    }
}

Describe 'Set-BMRelease' {
    It 'should update release' {
        $releaseNumber = New-TestReleaseNumber
        $release = New-BMRelease -Session $script:session -Application $script:app -Number $releaseNumber -Pipeline $script:pipeline
        $newPipeline = New-BMPipeline -Session $script:session -Name 'updating a release'
        $updatedRelease = Set-BMRelease -Session $script:session -Release $release -PipelineID $newPipeline.pipeline_id -Name 'new name'
        Assert-Release -Release $updatedRelease -HasName 'new name' -HasNumber $release.number -HasPipelineID $newPipeline.pipeline_id
    }

    It 'should not change anything' {
        $releaseNumber = New-TestReleaseNumber
        $release = New-BMRelease -Session $script:session -Application $script:app -Number $releaseNumber -Pipeline $script:pipeline
        $updatedRelease = Set-BMRelease -Session $script:session -Release $release
        Assert-Release -Release $updatedRelease -HasName $release.name -HasNumber $release.number -HasPipelineID $release.pipelineId
    }

    It 'should fail when update does not exist' {
        $Global:Error.Clear()
        $updatedRelease = Set-BMRelease -Session $script:session -Release -1 -ErrorAction SilentlyContinue
        $updatedRelease | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'Release\ "-1"\ does\ not\ exist\.'
    }
}
