
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $defaultObjectName = New-BMTestObjectName
    $raft = Set-BMRaft -Session $script:session -Raft $defaultObjectName -PassThru
    $script:app = New-BMApplication -Session $script:session -Name $defaultObjectName -Raft $raft

    $stages = & {
        New-BMPipelineStageTargetObject -PlanName 'Integration' -EnvironmentName 'Integration' -AllServers |
            New-BMPipelineStageObject -Name 'Publish-BMReleaseBuild.Fubar' |
            Write-Output

        New-BMPipelineStageTargetObject -PlanName 'Testing' -EnvironmentName 'Testing' -AllServers |
            New-BMPipelineStageObject -Name 'Publish-BMReleaseBuild.Fubar2' |
            Write-Output
    }

    $postDeployOptions = New-BMPipelinePostDeploymentOptionsObject -MarkDeployed $false

    $script:pipeline = Set-BMPipeline -Session $script:session `
                                      -Name $defaultObjectName `
                                      -Application $script:app `
                                      -Color '#ffffff' `
                                      -Stage $stages `
                                      -PostDeploymentOption $postDeployOptions `
                                      -PassThru `
                                      -ErrorAction Stop

    $script:release =
        New-BMRelease -Session $script:session -Application $script:app -Number '1.0' -Pipeline $script:pipeline

    function GivenBMReleaseBuild
    {
        $script:build = New-BMBuild -Session $script:session -Release $script:release
    }

    function WhenDeployingBuild
    {
        param(
            [string]
            $ToStage,

            [Switch]
            $Force
        )
        $Global:Error.Clear()

        $optionalParam = @{ }
        if( $Force )
        {
            $optionalParam['Force'] = $true
        }

        $Script:deployment =
            Publish-BMReleaseBuild -Session $script:session -Build $script:build $ToStage @optionalParam
    }

    function ThenShouldNotThrowErrors
    {
        $Global:Error | Should -BeNullOrEmpty
    }

    function ThenBuildShouldBeDeployed
    {
        param(
            [string]
            $ToStage
        )

        $timer = [Diagnostics.Stopwatch]::StartNew()
        $script:deployment | Should -Not -BeNullOrEmpty
        $deploymentId = $script:deployment.id
        $expectedStatuses = @('executing', 'pending', 'succeeded')
        do
        {
            $script:deployment = Invoke-BMRestMethod -Session $script:session `
                                                     -Name 'releases/builds/deployments' `
                                                     -Parameter @{ deploymentId = $deploymentId } `
                                                     -Method Post

            if (-not $script:deployment -or $script:deployment.status -notin $expectedStatuses)
            {
                Start-Sleep -Milliseconds 100
                continue
            }

            break
        }
        while ($timer.Elapsed.TotalSeconds -lt 10)

        $script:deployment | Should -Not -BeNullOrEmpty
        $script:deployment.pipelineName | Should -Be $script:pipeline.Pipeline_Name
        $script:deployment.pipelineStageName | Should -Be $ToStage
        $script:deployment.releaseId | Should -Be $script:release.id
        $script:deployment.status | Should -BeIn $expectedStatuses
    }
}

Describe 'Publish-BMReleaseBuild' {
    It 'should publish using build object' {
        GivenBMReleaseBuild
        WhenDeployingBuild
        ThenShouldNotThrowErrors
        ThenBuildShouldBeDeployed -ToStage 'Publish-BMReleaseBuild.Fubar'
    }

    It 'should deploy to specific stage' {
        GivenBMReleaseBuild
        WhenDeployingBuild -ToStage 'Publish-BMReleaseBuild.Fubar2'
        ThenShouldNotThrowErrors
        ThenBuildShouldBeDeployed -ToStage 'Publish-BMReleaseBuild.Fubar2'
    }

    It 'should fail if build does not exist' {
        $Global:Error.Clear()

        $deployment = Publish-BMReleaseBuild -Session $script:session -Build ([int32]::MaxValue) -ErrorAction SilentlyContinue
        $deployment | Should -BeNullOrEmpty
        $Global:Error.Count | Should -Be 1
    }

    It 'should force a deploy' {
        GivenBMReleaseBuild
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        WhenDeployingBuild -ToStage 'Integration' -Force
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter { $Parameter['force'] -eq 'true' }
    }
}