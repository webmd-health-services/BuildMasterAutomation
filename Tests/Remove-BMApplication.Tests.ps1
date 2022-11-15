
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    function GivenApp
    {
        $script:app = New-BMApplication -Session $BMTestSession -Name (New-BMTestObjectName)
    }

    function ThenApp
    {
        [CmdletBinding()]
        param(
            [switch] $Not,

            [switch] $Exists
        )

        $apps = $script:app | Get-BMApplication -Session $BMTestSession -ErrorAction Ignore

        if ($Not)
        {
            $apps | Should -BeNullOrEmpty
        }
        else
        {
            $apps | Should -Not -BeNullOrEmpty
        }
    }

    function WhenDeleting
    {
        [CmdletBinding()]
        param(
            $App = $script:app,

            $WithArgs = @{}
        )

        Remove-BMApplication -Session $BMTestSession -Application $App @WithArgs
    }
}

Describe 'Remove-BMApplication' {
    BeforeEach {
        $script:app = $null
        $Global:Error.Clear()
    }

    It 'should validate application' {
        WhenDeleting 'i do not exist' -ErrorAction SilentlyContinue
        ThenError -MatchesPattern 'application "i do not exist" because it does not exist'
    }

    It 'should not delete active application' {
        GivenApp
        WhenDeleting -ErrorAction SilentlyContinue
        ThenError -MatchesPattern "delete application ""$($script:app.Application_Name)"" because it is active"
    }

    It 'should allow deleting active applications' {
        GivenApp
        WhenDeleting -WithArgs @{ Force = $true }
        ThenApp -Not -Exists
    }
}