
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

Describe 'New-BMApplication.when application doesn''t exist' {
    $conn = New-BMTestSession
    $app = New-BMApplication -Session $conn -Name 'fubarsnafu'
    It 'should return the new application' -Skip {
        $app | Should -Not -BeNullOrEmpty
    }

    It 'should create the new application' -Skip {
        $freshApp = Get-BMApplication -Session $conn -Name 'fubarsnafu' 
        $freshApp | Should -Not -BeNullOrEmpty
        $freshApp.Application_Id | Should -Be $app.Application_Id
    }
}
