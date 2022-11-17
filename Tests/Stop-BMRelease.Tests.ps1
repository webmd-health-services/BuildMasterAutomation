
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:app = New-BMTestApplication -Session $session -CommandPath $PSCommandPath
    $script:pipeline = GivenAPipeline $app.Application_Name -ForApplication $app

    function GivenARelease
    {
        param(
            $Name,
            $Number
        )

        New-BMRelease -Session $session -Application $app -Number $Number -Pipeline $pipeline.Pipeline_Name -Name $Name
    }

    function ThenTheReleaseIsCancelled
    {
        param(
            $Number
        )

        $release =
            Get-BMRelease -Session $session -Application $app |
            Where-Object { $_.number -eq $Number }

        $release.status | Should -Be 'canceled'
    }

    function WhenCancellingTheRelease
    {
        param(
            $Application,
            $Number,
            $Reason
        )

        Stop-BMRelease -Session $session -Application $Application -Number $Number -Reason $Reason
    }
}

Describe 'Stop-BMRelease' {
    It 'should cancel with application id' {
        GivenARelease (New-BMTestObjectName) '3.4'
        WhenCancellingTheRelease $script:app.Application_Id '3.4'
        ThenTheReleaseIsCancelled '3.4'
    }

    It 'should cancel with application name' {
        GivenARelease (New-BMTestObjectName) '3.5'
        WhenCancellingTheRelease $script:app.Application_Name '3.5'
        ThenTheReleaseIsCancelled '3.5'
    }

    It 'should cancel with application object' {
        GivenARelease (New-BMTestObjectName) '3.6'
        WhenCancellingTheRelease $script:app '3.6'
        ThenTheReleaseIsCancelled '3.6'
    }

    # BuildMaster API doesn't expose a way to see the cancellation reason, so we mock the call.
    It 'should cancel when using reason' {
        Mock 'Invoke-BMNativeApiMethod' `
             -ModuleName 'BuildMasterAutomation' `
             -ParameterFilter { $Name -eq 'Releases_CancelRelease'}
        GivenARelease 'snafu' '3.7'
        WhenCancellingTheRelease $script:app.Application_Id '3.7' 'it looked at me funny'
        Should -Invoke 'Invoke-BMNativeApiMethod' `
                       -ModuleName 'BuildMasterAutomation' `
                       -ParameterFilter { $Parameter['CancelledReason_Text'] -eq 'it looked at me funny' }
    }
}