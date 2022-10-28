
#Requires -Version 5.1

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
}

Describe 'New-BMApplication' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should create new application' {
        $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
        $app = New-BMApplication -Session $script:session -Name $appName
        $app | Should -Not -BeNullOrEmpty
        $freshApp = Get-BMApplication -Session $script:session -Name $appName
        $freshApp | Should -Not -BeNullOrEmpty
        $freshApp.Application_Id | Should -Be $app.Application_Id
    }

    It 'should fail if application exists' {
        $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
        New-BMApplication -Session $script:session -Name $appName
        $app2 = New-BMApplication -Session $script:session -Name $appName -ErrorAction SilentlyContinue
        $Global:Error | Should -Match 'duplicate key'
        $app2 | Should -BeNullOrEmpty
    }

    It 'should set values for all parameters' {
        $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
        $app = New-BMApplication -Session $script:session `
                                 -Name $appName `
                                 -ReleaseNumberSchemeName DateBased `
                                 -BuildNumberSchemeName DateTimeBased `
                                 -AllowMultipleActiveBuilds
        $app | Should -Not -BeNullOrEmpty
        $app.ReleaseNumber_Scheme_Name | Should -Be 'DateBased'
        $app.BuildNumber_Scheme_Name | Should -Be 'DateTimeBased'
        $app.AllowMultipleActiveBuilds_Indicator | Should -Be $true
    }

    It 'should create application in an application group' {
        $appGroupID = Invoke-BMNativeApiMethod -Session $script:session `
                                               -Name 'ApplicationGroups_GetOrCreateApplicationGroup' `
                                               -Parameter @{ ApplicationGroup_Name = 'TestBMAppGroup' } `
                                               -Method Post
        $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
        $app = New-BMApplication -Session $script:session -Name $appName -ApplicationGroupId $appGroupID
        $app | Should -Not -BeNullOrEmpty
        $app.ApplicationGroup_Name | Should -Be 'TestBMAppGroup'
    }
}
