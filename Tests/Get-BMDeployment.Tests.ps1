
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    $script:application = New-BMApplication -Session $script:session -Name 'Get-BMDeployment.Tests.Application'
    $script:plan = Invoke-BMNativeApiMethod -Session $script:session `
                                     -Name 'Plans_CreatePlan' `
                                     -Method Post `
                                     -Parameter @{
                                        Plan_Name = 'Get-BMDeployment.Tests.Plan';
                                        Application_Id = $script:application.Application_Id;
                                        PlanType_Code = 'D';
                                     }
    $script:pipeline = New-BMPipeline -Session $script:session `
                                      -Name 'Get-BMDeployment.Tests.Pipeline' `
                                      -Application $script:application `
                                      -Color '#ffffff' `
                                      -Stage @'
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
    $script:releaseAll = New-BMRelease -Session $script:session `
                                       -Application $script:application `
                                       -Number '1.0' `
                                       -Pipeline $script:pipeline `
                                       -Name 'releaseAll'
    $script:releaseRelease = New-BMRelease -Session $script:session `
                                           -Application $script:application `
                                           -Number '2.0' `
                                           -Pipeline $script:pipeline `
                                           -Name 'releasePackage'
    $script:releaseRelease2 = New-BMRelease -Session $script:session `
                                            -Application $script:application `
                                            -Number '3.0' `
                                            -Pipeline $script:pipeline `
                                            -Name 'releaseRelease'
    Enable-BMEnvironment -Session $script:session -Name 'Integration'
    Enable-BMEnvironment -Session $script:session -Name 'Testing'
    Enable-BMEnvironment -Session $script:session -Name 'Production'

    function GivenReleasePackage
    {
        param(
            [object]
            $Release
        )

        New-BMPackage -Session $script:session -Release $Release.id
    }

    function GivenDeployment
    {
        param(
            [object]
            $Package,

            [string]
            $Stage
        )

        Publish-BMReleasePackage -Session $script:session -Package $Package.id $Stage -Force
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
            $script:application
        )

        $Global:Error.Clear()

        if( $ID )
        {
            $script:getDeployment = @(Get-BMDeployment -Session $script:session -ID $ID)
        }
        elseif( $Package )
        {
            $script:getDeployment = @(Get-BMDeployment -Session $script:session -Package $Package)
        }
        elseif( $Release )
        {
            $script:getDeployment = @(Get-BMDeployment -Session $script:session -Release $Release)
        }
        elseif( $script:application )
        {
            $script:getDeployment = @(Get-BMDeployment -Session $script:session -Application $script:application)
        }
        else
        {
            $script:getDeployment = @(Get-BMDeployment -Session $script:session)
        }
    }

    function ThenShouldNotThrowErrors
    {
        param(
        )

        $Global:Error | Should -BeNullOrEmpty
    }

    function ThenDeploymentShouldBeReturned
    {
        param(
            [object]
            $Deployment
        )

        $currentDeployment = $getDeployment | Where-Object { $_.id -eq $Deployment.id }

        $currentDeployment.id | Should -Match $Deployment.id
        $currentDeployment.packageNumber | Should -Match $Deployment.packageNumber
        $currentDeployment.applicationName | Should -Match $Deployment.applicationName
        $currentDeployment.releaseName | Should -Match $Deployment.releaseName
        $currentDeployment.pipelineStageName | Should -Match $Deployment.pipelineStageName
    }

    function ThenDeploymentShouldNotBeReturned
    {
        param(
            [object]
            $Deployment
        )

        $getDeployment | Where-Object { $_.id -eq $Deployment.id } | Should -BeNullOrEmpty
    }

    function ThenTotalDeploymentsReturned
    {
        param(
            [int]
            $Count
        )

        $getDeployment.Count | Should -Be $Count
    }
}

Describe 'Get-BMDeployment' {
    BeforeEach {
        $script:getDeployment = @()
        $Global:Error.Clear()
    }

    It 'should get all deployments' {
        $package = GivenReleasePackage $script:releaseAll
        $package2 = GivenReleasePackage $script:releaseAll
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

    It 'should get a specific deployment' {
        $package = GivenReleasePackage $script:releaseAll
        $package2 = GivenReleasePackage $script:releaseAll
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

    It 'should get deployment by packageId' {
        $package = GivenReleasePackage $script:releaseAll
        $package2 = GivenReleasePackage $script:releaseAll
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

    It 'should get deployment by packageNumber' {
        $package = GivenReleasePackage $script:releaseAll
        $package2 = GivenReleasePackage $script:releaseAll
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

    It 'should get deployment by releaseId' {
        $package = GivenReleasePackage $script:releaseRelease
        $package2 = GivenReleasePackage $script:releaseRelease
        $package3 = GivenReleasePackage $script:releaseAll
        $deployment = GivenDeployment $package
        $deployment2 = GivenDeployment $package2
        $deployment3 = GivenDeployment $package3
        WhenGettingBMDeployment -Release $script:releaseRelease.id
        ThenShouldNotThrowErrors
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
        ThenTotalDeploymentsReturned 2
    }

    It 'should get deployment by releaseName' {
        $package = GivenReleasePackage $script:releaseRelease
        $package2 = GivenReleasePackage $script:releaseRelease2
        $package3 = GivenReleasePackage $script:releaseRelease2
        $deployment = GivenDeployment $package
        $deployment2 = GivenDeployment $package2
        $deployment3 = GivenDeployment $package3
        $deployment4 = GivenDeployment $package3 -Stage 'Production'
        WhenGettingBMDeployment -Release $script:releaseRelease2.name
        ThenShouldNotThrowErrors
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldBeReturned $deployment3
        ThenDeploymentShouldBeReturned $deployment4
        ThenDeploymentShouldNotBeReturned $deployment
        ThenTotalDeploymentsReturned 3
    }

    It 'should get deployment by applicationId' {
        $package = GivenReleasePackage $script:releaseAll
        $package2 = GivenReleasePackage $script:releaseRelease
        $package3 = GivenReleasePackage $script:releaseRelease2
        $deployment = GivenDeployment $package
        $deployment2 = GivenDeployment $package2
        $deployment3 = GivenDeployment $package3
        WhenGettingBMDeployment -Application $script:application.Application_Id
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 22
    }

    It 'should get deployment by applicationName' {
        $package = GivenReleasePackage $script:releaseAll
        $package2 = GivenReleasePackage $script:releaseRelease
        $package3 = GivenReleasePackage $script:releaseRelease2
        $deployment = GivenDeployment $package
        $deployment2 = GivenDeployment $package2
        $deployment3 = GivenDeployment $package3
        WhenGettingBMDeployment -Application $script:application.Application_Name
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 25
    }
}