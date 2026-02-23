
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    function Init
    {
        $script:session = New-BMTestSession
        ClearBM

        $defaultObjectName = New-BMTestObjectName -Separator '_'

        $intEnvName = "${defaultObjectName}_Integration"
        New-BMEnvironment -Session $script:session -Name $intEnvName

        $testEnvName = "${defaultObjectName}_Testing"
        New-BMEnvironment -Session $script:session -Name $testEnvName

        $prodEnvName = "${defaultObjectName}_Production"
        New-BMEnvironment -Session $script:session -Name $prodEnvName

        New-BMServer -Session $script:session `
                     -Name $defaultObjectName `
                     -Environment $intEnvName, $testEnvName, $prodEnvName `
                     -Local

        $raft = Set-BMRaft -Session $script:session -Raft $defaultObjectName -PassThru

        $script:app = New-BMApplication -Session $script:session -Name $defaultObjectName -Raft $raft

        $planName = "${defaultObjectName}.ps1"
        Set-BMRAftItem -Session $script:session -TypeCode Script -RaftItem $planName -Application $script:app

        $stages = & {
            New-BMPipelineStageTargetObject -PlanName $planName -EnvironmentName $intEnvName -AllServers |
                New-BMPipelineStageObject -Name 'Integration' |
                Write-Output

            New-BMPipelineStageTargetObject -PlanName $planName -EnvironmentName $testEnvName -AllServers |
                New-BMPipelineStageObject -Name 'Testing' |
                Write-Output

            New-BMPipelineStageTargetObject -PlanName $planName -EnvironmentName $prodEnvName -AllServers |
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
    }

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

        $deploy = Publish-BMReleaseBuild -Session $script:session -Build $Build.id -Stage $Stage -Force

        # Wait for deploy to finish.
        while ($true)
        {
            if ($deploy.ended -or $deploy.status -ne 'pending')
            {
                break
            }

            Start-Sleep -Milliseconds 100
            $deploy = Get-BMDeployment -Session $script:session -Deployment $deploy
            Write-Verbose $deploy.status
        }

        return $deploy
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

            [String] $Status,

            [switch] $ShouldError
        )

        $parameters = $PSBoundParameters
        $parameters.Remove('ShouldError')

        $Global:Error.Clear()

        $script:result = @(Get-BMDeployment -Session $script:session @parameters)

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

    function ThenDeploymentMatches
    {
        param(
            [Parameter(Mandatory)]
            [Object] $Deploy,
            [String] $Deployment,
            [String] $Build,
            [String] $Release,
            [String] $Application,
            [String] $Environment,
            [String] $BuildNumber,
            [String] $Stage,
            [String] $Status
        )

        if ($Deployment)
        {
            $Deploy.id | Should -Be $Deployment
        }

        if ($BuildNumber)
        {
            $Deploy.buildNumber | Should -Be $BuildNumber
        }

        if ($Release)
        {
            $Deploy.releaseId | Should -Be $Release
        }

        if ($Application)
        {
            $Deploy.applicationName | Should -Be $Application
        }

        if ($Environment)
        {
            $Deploy.environmentName | Should -Be $Environment
        }

        if ($Stage)
        {
            $Deploy.pipelineStageName | Should -Be $Stage
        }

        if ($Status)
        {
            $Deploy.status | Should -Be $Status
        }
    }
}

Describe 'Get-BMDeployment' {
    BeforeEach {
        $script:result = @()
        $Global:Error.Clear()
        Init
        # $DebugPreference = 'Continue'
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
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Application $script:app.Application_Name
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 3
        $script:result | ForEach-Object { ThenDeploymentMatches $_ -Application $script:app.Application_Name }
    }

    It 'should get a deployment by application object' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseAll
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Application $script:app
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 3
        $script:result | ForEach-Object { ThenDeploymentMatches $_ -Application $script:app.Application_Name }
    }

    It 'should get a deployment by release object' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseRelease
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 1
        $script:result | ForEach-Object { ThenDeploymentMatches $_ -Release $script:releaseRelease.id }
    }

    It 'should get deployment by release id' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseRelease.id
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 1
        $script:result | ForEach-Object { ThenDeploymentMatches $_ -Release $script:releaseRelease.id }
    }

    It 'should get deployment by release name' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseRelease.name
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 1
        $script:result | ForEach-Object { ThenDeploymentMatches $_ -Release $script:releaseRelease.id }
    }

    It 'should get deployment by build object' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Build $build
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 2
        $script:result | ForEach-Object { ThenDeploymentMatches $_ -Build $build.id }
    }

    It 'should get deployment by build id' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Build $build.id
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 2
        $script:result | ForEach-Object { ThenDeploymentMatches $_ -Build $build.id }
    }

    It 'should get a deployment by pipeline stage name' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Stage 'Testing'
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 1
        $script:result | ForEach-Object { ThenDeploymentMatches $_ -Stage 'Testing' }
    }

    It 'should get by multiple parameters' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseAll -Stage 'Testing'
        ThenShouldNotThrowErrors
        ThenTotalDeploymentsReturned 1
        $script:result | ForEach-Object { ThenDeploymentMatches $_ -Release $script:releaseAll.id -Pipeline 'Testing' }
    }

    It 'should find no deployments' {
        $build = GivenReleaseBuild $script:releaseAll
        $build2 = GivenReleaseBuild $script:releaseRelease
        GivenDeployment $build
        GivenDeployment $build -Stage 'Testing'
        GivenDeployment $build2
        WhenGettingBMDeployment -Release $script:releaseRelease.id -Stage 'Testing' -Application $script:app
        ThenShouldThrowError
        ThenTotalDeploymentsReturned 0
    }
}