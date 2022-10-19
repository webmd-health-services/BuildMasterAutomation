
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    $nameSuffix = [IO.Path]::GetRandomFileName()
    $pipelineName = "Get-BMDeployment.Tests.Pipeline.$($nameSuffix)"

    $script:application = New-BMApplication -Session $script:session -Name "Get-BMDeployment.Tests.Application.$($nameSuffix)"

    $stages = & {
        New-BMPipelineStageTargetObject -PlanName 'Get-BMDeployment.Tests.Plan' -EnvironmentName 'Integration' -AllServers |
            New-BMPipelineStageObject -Name 'Integration' |
            Write-Output

        New-BMPipelineStageTargetObject -PlanName 'Get-BMDeployment.Tests.Plan' -EnvironmentName 'Testing' -AllServers |
            New-BMPipelineStageObject -Name 'Testing' |
            Write-Output

        New-BMPipelineStageTargetObject -PlanName 'Get-BMDeployment.Tests.Plan' -EnvironmentName 'Production' -AllServers |
            New-BMPipelineStageObject -Name 'Production' |
            Write-Output
    }

    $pipeline = Set-BMPipeline -Session $script:session `
                            -Name $pipelineName `
                            -Application $script:application `
                            -Color '#ffffff' `
                            -Stage $stages `
                            -PassThru `
                            -ErrorAction Stop

    $script:releaseAll =
        New-BMRelease -Session $script:session -Application $script:application -Pipeline $pipeline -Number '1.0' -Name 'releaseAll'
    $script:releaseRelease =
        New-BMRelease -Session $script:session -Application $script:application -Pipeline $pipeline -Number '2.0' -Name 'releaseBuild'
    $script:releaseRelease2 =
        New-BMRelease -Session $script:session -Application $script:application -Pipeline $pipeline -Number '3.0' -Name 'releaseRelease'

    Enable-BMEnvironment -Session $script:session -Name 'Integration'
    Enable-BMEnvironment -Session $script:session -Name 'Testing'
    Enable-BMEnvironment -Session $script:session -Name 'Production'

    function GivenReleaseBuild
    {
        param(
            [object]
            $Release
        )

        New-BMBuild -Session $script:session -Release $Release.id
    }

    function GivenDeployment
    {
        param(
            [object] $Build,

            [string]
            $Stage
        )

        Publish-BMReleaseBuild -Session $script:session -Build $Build.id $Stage -Force
    }

    function WhenGettingBMDeployment
    {
        param(
            [Object] $Deployment,

            [Object] $Build,

            [Object] $Release,

            [Object] $script:application
        )

        $Global:Error.Clear()

        $script:result = & {
            if( $Deployment )
            {
                Write-Debug "Getting by Deployment $($Deployment)"
                @(Get-BMDeployment -Session $script:session -Deployment $Deployment)
            }
            elseif( $Build )
            {
                Write-Debug 'Getting by Build.'
                @(Get-BMDeployment -Session $script:session -Build $Build)
            }
            elseif( $Release )
            {
                Write-Debug 'Getting by release.'
                @(Get-BMDeployment -Session $script:session -Release $Release)
            }
            elseif( $script:application )
            {
                Write-Debug 'Getting by application.'
                @(Get-BMDeployment -Session $script:session -Application $script:application)
            }
        }

        Write-Debug "Found $(($script:result | Measure-Object).Count) deployments."
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
            [Object] $Deployment
        )

        $currentDeployment = $script:result | Where-Object { $_.id -eq $Deployment.id }
        $currentDeployment | Should -Not -BeNullOrEmpty
        $currentDeployment.buildNumber | Should -Match $Deployment.buildNumber
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

        $script:result | Where-Object { $_.id -eq $Deployment.id } | Should -BeNullOrEmpty
    }

    function ThenTotalDeploymentsReturned
    {
        param(
            [int] $Count
        )

        if ($null -eq $script:result)
        {
            0 | Should -Be $Count
        }
        else
        {
            $script:result | Should -HaveCount $Count
        }
    }
}

Describe 'Get-BMDeployment' {
    BeforeEach {
        $script:result = @()
        $Global:Error.Clear()
    }

    It 'should get all deployments' -Skip {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseAll
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment
        ThenShouldNotThrowErrors
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldBeReturned $deployment3
        ThenTotalDeploymentsReturned 3
    }

    It 'should get a specific deployment by object' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseAll
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Deployment $deployment
        ThenShouldNotThrowErrors
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
        ThenTotalDeploymentsReturned 1
    }

    It 'should get a specific deployment by id' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseAll
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Deployment $deployment.id
        ThenShouldNotThrowErrors
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
        ThenTotalDeploymentsReturned 1
    }

    It 'should get deployment by buildId' -Skip {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseAll
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Build $build.id
        ThenShouldNotThrowErrors
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
        ThenTotalDeploymentsReturned 2
    }

    It 'should get deployment by buildNumber' -Skip {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseAll
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Build $build2.number
        ThenShouldNotThrowErrors
        ThenDeploymentShouldBeReturned $deployment3
        ThenDeploymentShouldNotBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenTotalDeploymentsReturned 1
    }

    It 'should get deployment by releaseId' -Skip {
        $build = GivenReleaseBuild $script:releaseRelease
        $build2 = GivenReleaseBuild $script:releaseRelease
        $build3 = GivenReleaseBuild $script:releaseAll
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build2
        $deployment3 = GivenDeployment $build3
        WhenGettingBMDeployment -Release $script:releaseRelease.id
        ThenShouldNotThrowErrors
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
        ThenTotalDeploymentsReturned 2
    }

    It 'should get deployment by releaseName' -Skip {
        $build = GivenReleaseBuild $script:releaseRelease
        $build2 = GivenReleaseBuild $script:releaseRelease2
        $build3 = GivenReleaseBuild $script:releaseRelease2
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build2
        $deployment3 = GivenDeployment $build3
        $deployment4 = GivenDeployment $build3 -Stage 'Production'
        WhenGettingBMDeployment -Release $script:releaseRelease2.name
        ThenShouldNotThrowErrors
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldBeReturned $deployment3
        ThenDeploymentShouldBeReturned $deployment4
        ThenDeploymentShouldNotBeReturned $deployment
        ThenTotalDeploymentsReturned 3
    }

    It 'should get deployment by applicationId' -Skip {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $build3 = GivenReleaseBuild $script:releaseRelease2
        GivenDeployment $build
        GivenDeployment $build2
        GivenDeployment $build3
        WhenGettingBMDeployment -Application $script:application.Application_Id
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 22
    }

    It 'should get deployment by applicationName' -Skip {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $build3 = GivenReleaseBuild $script:releaseRelease2
        GivenDeployment $build
        GivenDeployment $build2
        GivenDeployment $build3
        WhenGettingBMDeployment -Application $script:application.Application_Name
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 25
    }
}