
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession
$app = New-BMTestApplication -Session $session -CommandPath $PSCommandPath 
$pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())

# In order to deploy, a pipeline must have at least one stage that executes one plan.
$pipeline = New-BMPipeline -Session $session -Name $pipelineName -Application $app -Color '#ffffff' -Stage @'
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
$release = New-BMRelease -Session $session -Application $app -Number '1.0' -Pipeline $pipeline

function GivenBMReleasePackage
{
    $Script:package = New-BMPackage -Session $session -Release $release
}

function WhenDeployingPackage
{
    param(
        [string]
        $ToStage
    )
    $Global:Error.Clear()
    
    $Script:deployment = Publish-BMReleasePackage -Session $session -Package $package $ToStage
}

function ThenShouldNotThrowErrors
{
    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

function ThenPackageShouldBeDeployed
{
    param(
        [string]
        $ToStage
    )
    
    It 'should return the deployment object' {
        $deployment | Should -Not -BeNullOrEmpty
    }

    $deployment = Invoke-BMRestMethod -Session $session -Name 'releases/packages/deployments' -Parameter @{ packageId = $package.id }
    It 'should create the deployment' {
        $deployment | Should -Not -BeNullOrEmpty
    }

    It 'should deploy the package' {
        $deployment.pipelineId | Should -Be $pipeline.pipeline_id
        $deployment.pipelineStageName | Should -Be $ToStage
        $deployment.releaseId | Should -Be $release.id
        $deployment.status | Should -Be 'pending'
    }
}

Describe 'Publish-BMReleasePackage.when using package object' {
    GivenBMReleasePackage
    WhenDeployingPackage
    ThenShouldNotThrowErrors
    ThenPackageShouldBeDeployed -ToStage 'Fubar'
}

Describe 'Publish-BMReleasePackage.when deploying to a specific pipeline stage' {
    GivenBMReleasePackage
    WhenDeployingPackage -ToStage 'Fubar2'
    ThenShouldNotThrowErrors
    ThenPackageShouldBeDeployed -ToStage 'Fubar2'
}

Describe 'Publish-BMReleasePackage.when package does not exist' {
    $Global:Error.Clear()

    $deployment = Publish-BMReleasePackage -Session $session -Package ([int32]::MaxValue) -ErrorAction SilentlyContinue

    It 'should return nothing' {
        $deployment | Should -BeNullOrEmpty
    }

    It 'should write an error' {
        $Global:Error.Count | Should -Be 1
    }
}
