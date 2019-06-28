
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession

$application = New-BMApplication -Session $session -Name 'Get-BMDeployment.Tests.Application'
$plan = Invoke-BMNativeApiMethod -Session $session -Name 'Plans_CreatePlan' -Method Post -Parameter @{ Plan_Name = 'Get-BMDeployment.Tests.Plan'; Application_Id = $application.Application_Id; PlanType_Code = 'D' }
$pipeline = New-BMPipeline -Session $session -Name 'Get-BMDeployment.Tests.Pipeline' -Application $application -Color '#ffffff' -Stage @'
<Inedo.BuildMaster.Pipelines.PipelineStage Assembly="BuildMaster">
    <Properties Name="Integration" TargetExecutionMode="Parallel" AutoPromote="False">
        <Targets>
            <Inedo.BuildMaster.Pipelines.PipelineStageTarget Assembly="BuildMaster">
                <Properties PlanName="Get-BMDeployment.Tests.Plan" EnvironmentName="Integration" DefaultServerContext="Specific">
                    <ServerNames>
                        <Item>localhost</Item>
                    </ServerNames>
                    <ServerRoleNames />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageTarget>
        </Targets>
        <Gate>
            <Inedo.BuildMaster.Pipelines.PipelineStageGate Assembly="BuildMaster">
                <Properties>
                    <UserApprovals />
                    <GroupApprovals />
                    <DeploymentWindows />
                    <AutomaticApprovals />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageGate>
        </Gate>
        <PostDeploymentEventListeners />
        <Variables>{}</Variables>
    </Properties>
</Inedo.BuildMaster.Pipelines.PipelineStage>
<Inedo.BuildMaster.Pipelines.PipelineStage Assembly="BuildMaster">
    <Properties Name="Testing" TargetExecutionMode="Parallel" AutoPromote="False">
        <Targets>
            <Inedo.BuildMaster.Pipelines.PipelineStageTarget Assembly="BuildMaster">
                <Properties PlanName="Get-BMDeployment.Tests.Plan" EnvironmentName="Testing" DefaultServerContext="Specific">
                    <ServerNames>
                        <Item>localhost</Item>
                    </ServerNames>
                    <ServerRoleNames />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageTarget>
        </Targets>
        <Gate>
            <Inedo.BuildMaster.Pipelines.PipelineStageGate Assembly="BuildMaster">
                <Properties>
                    <UserApprovals />
                    <GroupApprovals />
                    <DeploymentWindows />
                    <AutomaticApprovals />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageGate>
        </Gate>
        <PostDeploymentEventListeners />
        <Variables>{}</Variables>
    </Properties>
</Inedo.BuildMaster.Pipelines.PipelineStage>
<Inedo.BuildMaster.Pipelines.PipelineStage Assembly="BuildMaster">
    <Properties Name="Production" TargetExecutionMode="Parallel" AutoPromote="False">
        <Targets>
            <Inedo.BuildMaster.Pipelines.PipelineStageTarget Assembly="BuildMaster">
                <Properties PlanName="Get-BMDeployment.Tests.Plan" EnvironmentName="Production" DefaultServerContext="Specific">
                    <ServerNames>
                        <Item>localhost</Item>
                    </ServerNames>
                    <ServerRoleNames />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageTarget>
        </Targets>
        <Gate>
            <Inedo.BuildMaster.Pipelines.PipelineStageGate Assembly="BuildMaster">
                <Properties>
                    <UserApprovals />
                    <GroupApprovals />
                    <DeploymentWindows />
                    <AutomaticApprovals />
                </Properties>
            </Inedo.BuildMaster.Pipelines.PipelineStageGate>
        </Gate>
        <PostDeploymentEventListeners />
        <Variables>{}</Variables>
    </Properties>
</Inedo.BuildMaster.Pipelines.PipelineStage>
'@
$releaseAll = New-BMRelease -Session $session -Application $application -Number '1.0' -Pipeline $pipeline -Name 'releaseAll'
$releaseRelease = New-BMRelease -Session $session -Application $application -Number '2.0' -Pipeline $pipeline -Name 'releasePackage'
$releaseRelease2 = New-BMRelease -Session $session -Application $application -Number '3.0' -Pipeline $pipeline -Name 'releaseRelease'
Enable-BMEnvironment -Session $session -Name 'Integration'
Enable-BMEnvironment -Session $session -Name 'Testing'
Enable-BMEnvironment -Session $session -Name 'Production'

function Init
{
    $script:getDeployment = @()
}

function GivenReleasePackage
{
    param(
        [object]
        $Release
    )

    New-BMPackage -Session $session -Release $Release.id
}

function GivenDeployment
{
    param(
        [object]
        $Package,

        [string]
        $Stage
    )

    Publish-BMReleasePackage -Session $session -Package $Package.id $Stage -Force
}

function WhenGettingBMDeployment
{
    param(
        [int]
        $ID,

        [object]
        $Package,

        [object]
        $Release,

        [object]
        $Application
    )

    $Global:Error.Clear()

    if( $ID )
    {
        $script:getDeployment = @(Get-BMDeployment -Session $session -ID $ID)
    }
    elseif( $Package )
    {
        $script:getDeployment = @(Get-BMDeployment -Session $session -Package $Package)
    }
    elseif( $Release )
    {
        $script:getDeployment = @(Get-BMDeployment -Session $session -Release $Release)
    }
    elseif( $Application )
    {
        $script:getDeployment = @(Get-BMDeployment -Session $session -Application $Application)
    }
    else
    {
        $script:getDeployment = @(Get-BMDeployment -Session $session)
    }
}

function ThenShouldNotThrowErrors
{
    param(
    )

    It 'should not throw any errors' {
        $Global:Error | Should -BeNullOrEmpty
    }
}

function ThenDeploymentShouldBeReturned
{
    param(
        [object]
        $Deployment
    )

    $currentDeployment = $getDeployment | Where-Object { $_.id -eq $Deployment.id }

    It ('should return deployment: {0}.' -f $Deployment.id) {
        $currentDeployment.id | Should -Match $Deployment.id
    }

    It ('should return deployment {0} for package: {1}.' -f $Deployment.id, $Deployment.packageNumber) {
        $currentDeployment.packageNumber | Should -Match $Deployment.packageNumber
    }

    It ('should return deployment {0} for application: {1}.' -f $Deployment.id, $Deployment.applicationName) {
        $currentDeployment.applicationName | Should -Match $Deployment.applicationName
    }

    It ('should return deployment {0} for release: {1}.' -f $Deployment.id, $Deployment.releaseName) {
        $currentDeployment.releaseName | Should -Match $Deployment.releaseName
    }

    It ('should deploy package {0} to stage: {1}.' -f $Deployment.packageNumber, $Deployment.pipelineStageName) {
        $currentDeployment.pipelineStageName | Should -Match $Deployment.pipelineStageName
    }
}

function ThenDeploymentShouldNotBeReturned
{
    param(
        [object]
        $Deployment
    )

    It ('should not return deployment: {0}.' -f $Deployment.id) {
        $getDeployment | Where-Object { $_.id -eq $Deployment.id } | Should -BeNullOrEmpty
    }
}

function ThenTotalDeploymentsReturned
{
    param(
        [int]
        $Count
    )

    It ('should return exactly {0} deployments.' -f $Count) {
        $getDeployment.Count | Should -Be $Count
    }
}

Describe 'Get-BMDeployment.when getting all deployments' {
    Init
    $package = GivenReleasePackage $releaseAll
    $package2 = GivenReleasePackage $releaseAll
    $deployment = GivenDeployment $package
    $deployment2 = GivenDeployment $package -Stage 'Testing'
    $deployment3 = GivenDeployment $package2
    WhenGettingBMDeployment
    ThenShouldNotThrowErrors
    ThenDeploymentShouldBeReturned $deployment
    ThenDeploymentShouldBeReturned $deployment2
    ThenDeploymentShouldBeReturned $deployment3
    ThenTotalDeploymentsReturned 3
}

Describe 'Get-BMDeployment.when getting a specific deployment' {
    Init
    $package = GivenReleasePackage $releaseAll
    $package2 = GivenReleasePackage $releaseAll
    $deployment = GivenDeployment $package
    $deployment2 = GivenDeployment $package -Stage 'Testing'
    $deployment3 = GivenDeployment $package2
    WhenGettingBMDeployment -ID $deployment.id
    ThenShouldNotThrowErrors
    ThenDeploymentShouldBeReturned $deployment
    ThenDeploymentShouldNotBeReturned $deployment2
    ThenDeploymentShouldNotBeReturned $deployment3
    ThenTotalDeploymentsReturned 1
}

Describe 'Get-BMDeployment.when getting deployment by packageId' {
    Init
    $package = GivenReleasePackage $releaseAll
    $package2 = GivenReleasePackage $releaseAll
    $deployment = GivenDeployment $package
    $deployment2 = GivenDeployment $package -Stage 'Testing'
    $deployment3 = GivenDeployment $package2
    WhenGettingBMDeployment -Package $package.id
    ThenShouldNotThrowErrors
    ThenDeploymentShouldBeReturned $deployment
    ThenDeploymentShouldBeReturned $deployment2
    ThenDeploymentShouldNotBeReturned $deployment3
    ThenTotalDeploymentsReturned 2
}

Describe 'Get-BMDeployment.when getting deployment by packageNumber' {
    Init
    $package = GivenReleasePackage $releaseAll
    $package2 = GivenReleasePackage $releaseAll
    $deployment = GivenDeployment $package
    $deployment2 = GivenDeployment $package -Stage 'Testing'
    $deployment3 = GivenDeployment $package2
    WhenGettingBMDeployment -Package $package2.number
    ThenShouldNotThrowErrors
    ThenDeploymentShouldBeReturned $deployment3
    ThenDeploymentShouldNotBeReturned $deployment
    ThenDeploymentShouldNotBeReturned $deployment2
    ThenTotalDeploymentsReturned 1
}

Describe 'Get-BMDeployment.when getting deployment by releaseId' {
    Init
    $package = GivenReleasePackage $releaseRelease
    $package2 = GivenReleasePackage $releaseRelease
    $package3 = GivenReleasePackage $releaseAll
    $deployment = GivenDeployment $package
    $deployment2 = GivenDeployment $package2
    $deployment3 = GivenDeployment $package3
    WhenGettingBMDeployment -Release $releaseRelease.id
    ThenShouldNotThrowErrors
    ThenDeploymentShouldBeReturned $deployment
    ThenDeploymentShouldBeReturned $deployment2
    ThenDeploymentShouldNotBeReturned $deployment3
    ThenTotalDeploymentsReturned 2
}

Describe 'Get-BMDeployment.when getting deployment by releaseName' {
    Init
    $package = GivenReleasePackage $releaseRelease
    $package2 = GivenReleasePackage $releaseRelease2
    $package3 = GivenReleasePackage $releaseRelease2
    $deployment = GivenDeployment $package
    $deployment2 = GivenDeployment $package2
    $deployment3 = GivenDeployment $package3
    $deployment4 = GivenDeployment $package3 -Stage 'Production'
    WhenGettingBMDeployment -Release $releaseRelease2.name
    ThenShouldNotThrowErrors
    ThenDeploymentShouldBeReturned $deployment2
    ThenDeploymentShouldBeReturned $deployment3
    ThenDeploymentShouldBeReturned $deployment4
    ThenDeploymentShouldNotBeReturned $deployment
    ThenTotalDeploymentsReturned 3
}

Describe 'Get-BMDeployment.when getting deployment by applicationId' {
    Init
    $package = GivenReleasePackage $releaseAll
    $package2 = GivenReleasePackage $releaseRelease
    $package3 = GivenReleasePackage $releaseRelease2
    $deployment = GivenDeployment $package
    $deployment2 = GivenDeployment $package2
    $deployment3 = GivenDeployment $package3
    WhenGettingBMDeployment -Application $application.Application_Id
    ThenShouldNotThrowErrors
    ThenTotalDeploymentsReturned 22
}

Describe 'Get-BMDeployment.when getting deployment by applicationName' {
    Init
    $package = GivenReleasePackage $releaseAll
    $package2 = GivenReleasePackage $releaseRelease
    $package3 = GivenReleasePackage $releaseRelease2
    $deployment = GivenDeployment $package
    $deployment2 = GivenDeployment $package2
    $deployment3 = GivenDeployment $package3
    WhenGettingBMDeployment -Application $application.Application_Name
    ThenShouldNotThrowErrors
    ThenTotalDeploymentsReturned 25
}
