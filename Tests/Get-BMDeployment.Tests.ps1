
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    $nameSuffix = [IO.Path]::GetRandomFileName()
    $pipelineName = "Get-BMDeployment.Tests.Pipeline.$($nameSuffix)"

    $script:app =
        New-BMApplication -Session $script:session -Name "Get-BMDeployment.Tests.Application.$($nameSuffix)"

    $plan = Set-BMRaftItem -Session $script:session `
                           -Application $script:app `
                           -Raft 1 `
                           -RaftItem 'Get-BMDeployment.Tests.Plan' `
                           -TypeCode DeploymentPlan `
                           -Content "$([Environment]::NewLine)Log-Information `$ServerName;$([Environment]::NewLine)" `
                           -PassThru

    $stages = & {
        New-BMPipelineStageTargetObject -PlanName $plan.RaftItem_Name -EnvironmentName 'Integration' -AllServers |
            New-BMPipelineStageObject -Name 'Integration' |
            Write-Output

        New-BMPipelineStageTargetObject -PlanName $plan.RaftItem_Name -EnvironmentName 'Testing' -AllServers |
            New-BMPipelineStageObject -Name 'Testing' |
            Write-Output

        New-BMPipelineStageTargetObject -PlanName $plan.RaftItem_Name -EnvironmentName 'Production' -AllServers |
            New-BMPipelineStageObject -Name 'Production' |
            Write-Output
    }

    $pipeline = Set-BMPipeline -Session $script:session `
                            -Name $pipelineName `
                            -Application $script:app `
                            -Color '#ffffff' `
                            -Stage $stages `
                            -PassThru `
                            -ErrorAction Stop

    $script:releaseAll =
        New-BMRelease -Session $script:session -Application $script:app -Pipeline $pipeline -Number '1.0' -Name 'releaseAll'
    $script:releaseRelease =
        New-BMRelease -Session $script:session -Application $script:app -Pipeline $pipeline -Number '2.0' -Name 'releaseBuild'
    $script:releaseRelease2 =
        New-BMRelease -Session $script:session -Application $script:app -Pipeline $pipeline -Number '3.0' -Name 'releaseRelease'

    'Integration' | Enable-BMEnvironment -Session $script:session
    'Testing' | Enable-BMEnvironment -Session $script:session
    'Production' | Enable-BMEnvironment -Session $script:session

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
            [Object] $Build,

            [String] $Stage
        )

        return Publish-BMReleaseBuild -Session $script:session -Build $Build.id -Stage $Stage -Force
    }

    function WhenGettingBMDeployment
    {
        param(
            [Object] $Deployment,

            [Object] $Build,

            [Object] $Release,

            [Object] $Application
        )

        $Global:Error.Clear()

        # It can take several seconds
        do
        {
            $script:result = & {
                if( $Deployment )
                {
                    Write-Debug "Getting by Deployment $($Deployment)"
                    @(Get-BMDeployment -Session $script:session -Deployment $Deployment)
                }
                elseif( $Build )
                {
                    Write-Debug "Getting by Build $($Build)."
                    @(Get-BMDeployment -Session $script:session -Build $Build)
                }
                elseif( $Release )
                {
                    Write-Debug "Getting by release $($Release)."
                    @(Get-BMDeployment -Session $script:session -Release $Release)
                }
                elseif( $Application )
                {
                    Write-Debug "Getting by application $($Application)."
                    @(Get-BMDeployment -Session $script:session -Application $Application)
                }
                else
                {
                    Write-Debug "Getting all."
                    @(Get-BMDeployment -Session $script:session)
                }
            }

            if ($script:result)
            {
                break
            }

            Start-Sleep -Milliseconds 100
        }
        while ($timer.Elapsed.TotalSeconds -lt 10)

        $script:result | ft -auto | out-string | write-debug

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

        $script:result | ft -auto | out-string | write-debug

        $currentDeployment = $script:result | Where-Object { $_.id -eq $Deployment.id }
        $currentDeployment | Should -Not -BeNullOrEmpty -Because "didn't return deployment $($Deployment.id)"
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
}