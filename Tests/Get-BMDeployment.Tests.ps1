
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
        New-BMPipelineStageTargetObject -PlanName $raft.Raft_Name -EnvironmentName 'Integration' -AllServers |
            New-BMPipelineStageObject -Name 'Integration' |
            Write-Output

        New-BMPipelineStageTargetObject -PlanName $raft.Raft_Name -EnvironmentName 'Testing' -AllServers |
            New-BMPipelineStageObject -Name 'Testing' |
            Write-Output

        New-BMPipelineStageTargetObject -PlanName $raft.Raft_Name -EnvironmentName 'Production' -AllServers |
            New-BMPipelineStageObject -Name 'Production' |
            Write-Output
    }

    $script:pipeline = Set-BMPipeline -Session $script:session `
                               -Name $defaultObjectName `
                               -Application $script:app `
                               -Color '#ffffff' `
                               -Stage $stages `
                               -PassThru `
                               -ErrorAction Stop

    $script:releaseAll = New-BMRelease -Session $script:session `
                                       -Application $script:app `
                                       -Pipeline $script:pipeline `
                                       -Number '1.0' `
                                       -Name 'releaseAll'
    $script:releaseRelease = New-BMRelease -Session $script:session `
                                           -Application $script:app `
                                           -Pipeline $script:pipeline `
                                           -Number '2.0' `
                                           -Name 'releaseBuild'
    $script:releaseRelease2 = New-BMRelease -Session $script:session `
                                            -Application $script:app `
                                            -Pipeline $script:pipeline `
                                            -Number '3.0' `
                                            -Name 'releaseRelease'
    Start-Sleep -Seconds 2

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
        [CmdletBinding()]
        param(
            [Object] $Deployment,

            [Object] $Build,

            [Object] $Release,

            [Object] $Application,

            [Object] $Environment,

            [String] $BuildNumber,

            [String] $Pipeline,

            [String] $Stage,

            [String] $Status
        )

        $Global:Error.Clear()

        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        do {
            Start-Sleep -Milliseconds 500
            $script:result = & {
                @(Get-BMDeployment -Session $script:session @PSBoundParameters -ErrorAction 'SilentlyContinue')
            }

            if ($script:result)
            {
                break
            }
        } while ($timer.elapsed.totalseconds -lt 10)

        if ($script:result)
        {
            break
        }

        $script:result | Format-Table -Auto | Out-String | Write-Debug

        Write-Debug "Found $(($script:result | Measure-Object).Count) deployments."
    }

    function ThenShouldNotThrowErrors
    {
        param(
        )

        $Global:Error | Should -BeNullOrEmpty
    }

    function ThenShouldThrowError
    {
        param(
        )

        $Global:Error | Should -Not -BeNullOrEmpty
    }

    function ThenDeploymentShouldBeReturned
    {
        param(
            [Object] $Deployment
        )

        $script:result | ft -auto | out-string | write-debug

        $currentDeployment = $script:result | Where-Object { $_.id -eq $Deployment.id }
        Write-Debug "Looking for deployment $($Deployment.ToString())"
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
        ThenTotalDeploymentsReturned 1
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
    }

    It 'should get a specific deployment by id' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseAll
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Deployment $deployment.id
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 1
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
    }

    It 'should get a deployment by application name' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseAll
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Application $script:app.Application_Name
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 3
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldBeReturned $deployment3
    }

    It 'should get a deployment by application object' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseAll
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Application $script:app
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 3
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldBeReturned $deployment3
    }

    It 'should get a deployment by release object' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseRelease
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 1
        ThenDeploymentShouldNotBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenDeploymentShouldBeReturned $deployment3
    }

    It 'should get deployment by release id' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseRelease.id
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 1
        ThenDeploymentShouldNotBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenDeploymentShouldBeReturned $deployment3
    }

    It 'should get deployment by release name' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseRelease.name
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 1
        ThenDeploymentShouldNotBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenDeploymentShouldBeReturned $deployment3
    }

    It 'should get deployment by build object' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Build $build
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 2
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
    }

    It 'should get deployment by build id' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Build $build.id
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 2
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
    }

    It 'should get deployment by pipeline name' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Pipeline $script:pipeline.Pipeline_Name
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 2
        ThenDeploymentShouldBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
    }

    It 'should get a deployment by pipeline stage name' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Stage 'Testing'
        ThenShouldNotThrowErrors
        ThenDeploymentShouldNotBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
        ThenTotalDeploymentsReturned 1
    }

    It 'should get a deployment by status' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Status 'failed'
        ThenShouldNotThrowErrors
        ThenDeploymentShouldNotBeReturned $deployment
        ThenDeploymentShouldBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
        ThenTotalDeploymentsReturned 1
    }

    It 'should get by multiple parameters' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseAll -Pipeline 'Testing'
        ThenShouldNotThrowErrors
        ThenDeploymentShouldNotBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
        ThenTotalDeploymentsReturned 0
    }

    It 'should find no deployments' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        $deployment = GivenDeployment $build
        $deployment2 = GivenDeployment $build -Stage 'Testing'
        $deployment3 = GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseRelease -Stage 'Testing' -Application $script:app
        ThenShouldThrowError
        ThenDeploymentShouldNotBeReturned $deployment
        ThenDeploymentShouldNotBeReturned $deployment2
        ThenDeploymentShouldNotBeReturned $deployment3
        ThenTotalDeploymentsReturned 0
    }
}