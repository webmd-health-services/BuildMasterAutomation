
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $session = New-BMTestSession
    $app = New-BMTestApplication -Session $session -CommandPath $PSCommandPath
    $pipeline = Set-BMPipeline -Session $session -Name $app.Application_Name -Application $app -PassThru

    function GivenARelease
    {
        param(
            $Name,
            $Number
        )

        New-BMRelease -Session $session -Application $app -Number $Number -Pipeline $pipeline.Pipeline_Name -Name $Name
    }

    function Init
    {
        $script:app = $null
    }

    function ThenTheReleaseIsCancelled
    {
        param(
            $Number
        )

        $release = Get-BMRelease -Session $session -Application $app |
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
    It 'should cancel using application object' {
        GivenARelease 'fubar' '3.4'
        WhenCancellingTheRelease $app.Application_Id '3.4'
        ThenTheReleaseIsCancelled '3.4'
    }

    # BuildMaster API doesn't expose a way to see the cancellation reason, so we mock the call.
    It 'should cancel when using reason' {
        Mock -CommandName 'Invoke-BMNativeApiMethod' -ModuleName 'BuildMasterAutomation'
        GivenARelease 'snafu' '3.5'
        WhenCancellingTheRelease $app.Application_Id '3.5' 'it looked at me funny'
        Assert-MockCalled -CommandName 'Invoke-BMNativeApiMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter { $Parameter['CancelledReason_Text'] -eq 'it looked at me funny' }
    }
}