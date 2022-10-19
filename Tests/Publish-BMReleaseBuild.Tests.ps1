
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:app = New-BMTestApplication -Session $script:session -CommandPath $PSCommandPath
    $script:pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())

    # In order to deploy, a pipeline must have at least one stage that executes one plan.
    $script:pipeline = New-BMPipeline -Session $script:session `
                                      -Name $script:pipelineName `
                                      -Application $script:app `
                                      -Color '#ffffff' `
                                      -Stage @'
<Inedo.BuildMaster.Pipelines.PipelineStage Assembly="BuildMaster">
    <Properties Name="Fubar" TargetExecutionMode="Parallel" AutoPromote="False">
        <Targets>
            <Inedo.BuildMaster.Pipelines.PipelineStageTarget Assembly="BuildMaster">
                <Properties PlanName="Fubar" EnvironmentName="Integration" DefaultServerContext="None">
                    <ServerNames />
                    <ServerRoleNames />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageTarget>
        </Targets>
        <Gate>
            <Inedo.BuildMaster.Pipelines.PipelineStageGate Assembly="BuildMaster">
                <Properties>
                    <UserApprovals />
                    <GroupApprovals />
                    <AutomaticApprovals />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageGate>
        </Gate>
        <PostDeploymentEventListeners />
        <Variables>{}</Variables>
    </Properties>
</Inedo.BuildMaster.Pipelines.PipelineStage>
'@, @'
<Inedo.BuildMaster.Pipelines.PipelineStage Assembly="BuildMaster">
    <Properties Name="Fubar2" TargetExecutionMode="Parallel" AutoPromote="False">
        <Targets>
            <Inedo.BuildMaster.Pipelines.PipelineStageTarget Assembly="BuildMaster">
                <Properties PlanName="Fubar" EnvironmentName="Integration" DefaultServerContext="None">
                    <ServerNames />
                    <ServerRoleNames />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageTarget>
        </Targets>
        <Gate>
            <Inedo.BuildMaster.Pipelines.PipelineStageGate Assembly="BuildMaster">
                <Properties>
                    <UserApprovals />
                    <GroupApprovals />
                    <AutomaticApprovals />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageGate>
        </Gate>
        <PostDeploymentEventListeners />
        <Variables>{}</Variables>
    </Properties>
</Inedo.BuildMaster.Pipelines.PipelineStage>
'@
    $release = New-BMRelease -Session $script:session -Application $script:app -Number '1.0' -Pipeline $script:pipeline
    Enable-BMEnvironment -Session $script:session -Name 'Integration'

    function GivenBMReleasePackage
    {
        $Script:package = New-BMPackage -Session $script:session -Release $release
    }

    function WhenDeployingPackage
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

        $Script:deployment = Publish-BMReleasePackage -Session $script:session -Package $package $ToStage @optionalParam
    }

    function ThenShouldNotThrowErrors
    {
        $Global:Error | Should -BeNullOrEmpty
    }

    function ThenPackageShouldBeDeployed
    {
        param(
            [string]
            $ToStage
        )

        $deployment | Should -Not -BeNullOrEmpty
        $deployment = Invoke-BMRestMethod -Session $script:session -Name 'releases/packages/deployments' -Parameter @{ packageId = $package.id } -Method Post
        $deployment | Should -Not -BeNullOrEmpty
        $deployment.pipelineId | Should -Be $script:pipeline.pipeline_id
        $deployment.pipelineStageName | Should -Be $ToStage
        $deployment.releaseId | Should -Be $release.id
        $deployment.status | Should -Be 'pending'
    }
}

Describe 'Publish-BMReleasePackage' {
    It 'should publish using package object' {
        GivenBMReleasePackage
        WhenDeployingPackage
        ThenShouldNotThrowErrors
        ThenPackageShouldBeDeployed -ToStage 'Fubar'
    }

    It 'should deploy to specific stage' {
        GivenBMReleasePackage
        WhenDeployingPackage -ToStage 'Fubar2'
        ThenShouldNotThrowErrors
        ThenPackageShouldBeDeployed -ToStage 'Fubar2'
    }

    It 'should fail if package does not exist' {
        $Global:Error.Clear()

        $deployment = Publish-BMReleasePackage -Session $script:session -Package ([int32]::MaxValue) -ErrorAction SilentlyContinue
        $deployment | Should -BeNullOrEmpty
        $Global:Error.Count | Should -Be 1
    }

    It 'should force a deploy' {
        GivenBMReleasePackage
        Mock -CommandName 'Invoke-BMRestMethod' -ModuleName 'BuildMasterAutomation'
        WhenDeployingPackage -ToStage 'Fubar2' -Force
        Assert-MockCalled -CommandName 'Invoke-BMRestMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter { $Parameter['force'] -eq 'true' }
    }
}