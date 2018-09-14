
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession 
$app = New-BMTestApplication -Session $session -CommandPath $PSCommandPath
$pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())
$pipeline = New-BMPipeline -Session $session -Name $pipelineName -Application $app -Color '#ffffff'

function Assert-Release
{
    param(
        [Parameter(ValueFromPipeline=$true)]
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

        It 'should return the release' {
            $Release | Should -Not -BeNullOrEmpty
        }

        It 'should create the release' {
            $newRelease = $Release | Get-BMRelease -Session $session 
            $newRelease | Should -Not -BeNullOrEmpty
            $newRelease.id | Should -Be $Release.id
        }

        It 'should set application' {
            $Release.applicationId | Should -Be $app.Application_Id
        }

        It 'should set release number' {
            $Release.number | Should -Be $HasNumber
        }

        if( -not $HasPipelineID )
        {
            $HasPipelineID = $pipeline.Pipeline_Id
        }
        It 'should set pipeline' {
            $Release.pipelineId | Should -Be $HasPipelineID
        }

        if( -not $HasName )
        {
            $HasName = $HasNumber
        }

        It 'should set name' {
            $Release.name | Should -Be $HasName
        }
    }

    end
    {
        It ('should return the release') {
            $processedSomething | Should -BeTrue
        }
    }
}

function New-TestReleaseNumber
{
    [IO.Path]::GetRandomFileName()
}

Describe 'Set-BMRelease.when updating a release' {
    $releaseNumber = New-TestReleaseNumber
    $release = New-BMRelease -Session $session -Application $app -Number $releaseNumber -Pipeline $pipeline
    $newPipeline = New-BMPipeline -Session $session -Name 'updating a release'
    $updatedRelease = Set-BMRelease -Session $session -Release $release -PipelineID $newPipeline.pipeline_id -Name 'new name'
    Assert-Release -Release $updatedRelease -HasName 'new name' -HasNumber $release.number -HasPipelineID $newPipeline.pipeline_id
}

Describe 'Set-BMRelease.when not changing anything' {
    $releaseNumber = New-TestReleaseNumber
    $release = New-BMRelease -Session $session -Application $app -Number $releaseNumber -Pipeline $pipeline
    $updatedRelease = Set-BMRelease -Session $session -Release $release
    Assert-Release -Release $updatedRelease -HasName $release.name -HasNumber $release.number -HasPipelineID $release.pipelineId
}

Describe 'Set-BMRelease.when release doesn''t exist' {
    $Global:Error.Clear()
    $updatedRelease = Set-BMRelease -Session $session -Release -1 -ErrorAction SilentlyContinue
    It ('should return nothing') {
        $updatedRelease | Should -BeNullOrEmpty
    }
    It ('should write an error') {
        $Global:Error | Should -Match 'Release\ "-1"\ does\ not\ exist\.'
    }
}
