
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    Write-Verbose -Message "Creating deployments."
    $script:session = New-BMTestSession
    [Object[]] $script:result = @()

    $name = New-BMTestObjectName -Separator '_'

    $intEnvName = "${name}_Integration"
    New-BMEnvironment -Session $script:session -Name $intEnvName

    $testEnvName = "${name}_Testing"
    New-BMEnvironment -Session $script:session -Name $testEnvName

    $prodEnvName = "${name}_Production"
    New-BMEnvironment -Session $script:session -Name $prodEnvName

    New-BMServer -Session $script:session -Name $name -Environment $intEnvName, $testEnvName, $prodEnvName -Local

    $raft = Set-BMRaft -Session $script:session -Raft $name -PassThru

    $script:app = New-BMApplication -Session $script:session -Name $name -Raft $raft

    $planName = "${name}.ps1"
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
                                      -Name $name `
                                      -Application $script:app `
                                      -Color '#ffffff' `
                                      -Stage $stages `
                                      -PassThru `
                                      -ErrorAction Stop

    $newBMReleaseArgs = @{ Session = $script:session ; Application = $script:app ; Pipeline = $script:pipeline }
    $script:release1 = New-BMRelease @newBMReleaseArgs -Number '1.0'
    $script:v1Build1 = New-BMBuild -Session $script:session -Release $script:release1
    $script:v1Build1DeployToInt = Publish-BMReleaseBuild -Session $script:session -Build $script:v1Build1.id -Force
    $script:v1Build1DeployToTest =
        Publish-BMReleaseBuild -Session $script:session -Build $script:v1Build1.id -Force -Stage 'Testing'
    $script:v1Build2 = New-BMBuild -Session $script:session -Release $script:release1
    $script:v1Build2DeployToInt = Publish-BMReleaseBuild -Session $script:session -Build $script:v1Build2.id -Force

    $script:release2 = New-BMRelease @newBMReleaseArgs -Number '2.0'
    $script:v2Build1 = New-BMBuild -Session $script:session -Release $script:release2
    $script:v2Build1DeployToInt = Publish-BMReleaseBuild -Session $script:session -Build $script:v2Build1.id -Force

    $script:release3 = New-BMRelease @newBMReleaseArgs -Number '3.0'
    Write-Verbose "Finished creating deployments."

    Write-Verbose "Waiting for deployments to complete."

    $script:v1Deploys = @($script:v1Build1DeployToInt, $script:v1Build1DeployToTest, $script:v1Build2DeployToInt)
    $script:v1DeploysToInt = @($script:v1Build1DeployToInt, $script:v1Build2DeployToInt)
    $script:v1Build1Deploys = @($script:v1Build1DeployToInt, $script:v1Build1DeployToTest)
    $script:v2Deploys = @($script:v2Build1DeployToInt)
    $script:deploysToTest = @($script:v1Build1DeployToTest)
    $script:allDeploys = @(
        $script:v1Build1DeployToInt,
        $script:v1Build1DeployToTest,
        $script:v1Build2DeployToInt,
        $script:v2Build1DeployToInt
    )

    foreach ($deploy in $script:allDeploys)
    {
        while ($true)
        {
            if ($deploy.ended -or $deploy.status -ne 'pending')
            {
                break
            }

            Start-Sleep -Milliseconds 100
            $deploy = Get-BMDeployment -Session $script:session -Deployment $deploy
            $msg = "$($deploy.applicationName) > v$($deploy.releaseName)+$($deploy.buildNumber) > " +
                   "$($deploy.pipelineName) > $($deploy.pipelineStageName) > $($deploy.status)"
            Write-Verbose $msg
        }
    }
    Write-Verbose "Deployments completed."

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

        $parameters = $PSBoundParameters

        $Global:Error.Clear()

        $script:result = Get-BMDeployment -Session $script:session @parameters

        $script:result | Format-Table -Auto | Out-String | Write-Debug

        Write-Debug "Found $(($script:result | Measure-Object).Count) deployments."
    }

    function ThenError
    {
        param(
            [String] $MatchesRegex,
            [switch] $IsEmpty
        )

        if ($MatchesRegex)
        {
            $Global:Error | Should -Match $MatchesRegex
        }

        if ($IsEmpty)
        {
            $Global:Error | Should -BeNullOrEmpty
        }
    }

    function ThenReturns
    {
        param(
            [Object[]] $Deployments
        )

        $script:result | ft -auto | out-string | write-debug

        $script:result | Should -HaveCount ($Deployments.Count)

        foreach ($expectedDeploy in $Deployments)
        {
            # make sure a deployment with a specific id was returned.
            if ($expectedDeploy -is [int] -or $expectedDeploy -is [long])
            {
                $script:result | Where-Object 'id' -EQ $expectedDeploy | Should -HaveCount 1
                continue
            }

            # When kicking off a deploy, cuildMaster creates a parent deploy which creates a child deploy that does the
            # actual work. When you get deployments by any other filter thatn deployment ID, the API returns the child
            # deploys, never the parent deploys. There is no way to get the child or parent deploy.
            $script:result |
                Where-Object 'applicationId' -EQ $expectedDeploy.applicationId |
                Where-Object 'releaseNumber' -EQ $expectedDeploy.releaseNumber |
                Where-Object 'pipelineName' -EQ $expectedDeploy.pipelineName |
                Where-Object 'pipelineStageName' -EQ $expectedDeploy.pipelineStageName |
                Where-Object 'buildId' -EQ $expectedDeploy.buildId |
                Should -HaveCount 1

        }
    }
}

Describe 'Get-BMDeployment' {
    BeforeEach {
        $script:result = @()
        $Global:Error.Clear()
    }

    It 'gets deployment by object' {
        WhenGettingBMDeployment -Deployment $script:v1Build1DeployToInt
        ThenReturns $script:v1Build1DeployToInt.id
        ThenError -IsEmpty
    }

    It 'gets deployment by id' {
        WhenGettingBMDeployment -Deployment $script:v1Build1DeployToInt.id
        ThenReturns $script:v1Build1DeployToInt.id
        ThenError -IsEmpty
    }

    It 'gets deployment by application name' {
        WhenGettingBMDeployment -Application $script:app.Application_Name
        ThenReturns $script:allDeploys
        ThenError -IsEmpty
    }

    It 'gets deployments by application object' {
        WhenGettingBMDeployment -Application $script:app
        ThenReturns $script:allDeploys
        ThenError -IsEmpty
    }

    It 'gets deployment by release object' {
        WhenGettingBMDeployment -Release $script:release2
        ThenReturns $script:v2Deploys
        ThenError -IsEmpty
    }

    It 'gets deployments by release id' {
        WhenGettingBMDeployment -Release $script:release2.id
        ThenReturns $script:v2Deploys
        ThenError -IsEmpty
    }

    It 'gets deployments by release name' {
        WhenGettingBMDeployment -Release $script:release2.name
        ThenReturns $script:v2Deploys
        ThenError -IsEmpty
    }

    It 'gets deployment by build object' {
        WhenGettingBMDeployment -Build $script:v1Build1
        ThenReturns $script:v1Build1Deploys
        ThenError -IsEmpty
    }

    It 'gets deployment by build id' {
        WhenGettingBMDeployment -Build $script:v1Build1.id
        ThenReturns $script:v1Build1Deploys
        ThenError -IsEmpty
    }

    It 'gets deployment by pipeline stage name' {
        WhenGettingBMDeployment -Stage 'Testing'
        ThenError -IsEmpty
        ThenReturns $script:deploysToTest
    }

    It 'filters with multiple criteria' {
        WhenGettingBMDeployment -Release $script:release1 -Stage 'Integration'
        ThenError -IsEmpty
        ThenReturns $script:v1DeploysToInt
    }

    Context 'no deployments match' {
        It 'writes an error' {
            try
            {
                WhenGettingBMDeployment -Release $script:release2.id `
                                        -Stage 'Testing' `
                                        -Application $script:app `
                                        -ErrorAction SilentlyContinue
            }
            catch
            {
                Write-Warning $_
                $_ | Format-List * -Force | Out-String | Write-Warning
            }
            ThenError -Matches 'no deployments exist that match'
            ThenError -Matches 'applicationId'
            ThenError -Matches 'releaseId'
            ThenError -matches 'pipelineStageName'
            ThenReturns @()
        }
    }
}