
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$conn = New-BMTestSession

Describe 'New-BMApplication.when application doesn''t exist' {
    $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
    $app = New-BMApplication -Session $conn -Name $appName
    It 'should return the new application' {
        $app | Should -Not -BeNullOrEmpty
    }

    It 'should create the new application' {
        $freshApp = Get-BMApplication -Session $conn -Name $appName
        $freshApp | Should -Not -BeNullOrEmpty
        $freshApp.Application_Id | Should -Be $app.Application_Id
    }
}

Describe 'New-BMApplication.when application exists' {
    $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
    $app = New-BMApplication -Session $conn -Name $appName
    $Global:Error.Clear()
    $app2 = New-BMApplication -Session $conn -Name $appName -ErrorAction SilentlyContinue
    It 'should fail' {
        $Global:Error | Should -Match 'duplicate key'
    }

    It 'should return nothing' {
        $app2 | Should -BeNullOrEmpty
    }
}

Describe 'New-BMApplication.when creating application with all parameters' {
    $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
    $app = New-BMApplication -Session $conn -Name $appName -ReleaseNumberSchemeName DateBased -BuildNumberSchemeName DateTimeBased -AllowMultipleActiveBuilds
    It 'should return the new application' {
        $app | Should -Not -BeNullOrEmpty
    }

    It 'should set release number scheme' {
        $app.ReleaseNumber_Scheme_Name | Should -Be 'DateBased'
    }

    It 'should set build number scheme' {
        $app.BuildNumber_Scheme_Name | Should -Be 'DateTimeBased'
    }

    It 'should set allow multiple active build' {
        $app.AllowMultipleActiveBuilds_Indicator | Should -Be $true
    }
}