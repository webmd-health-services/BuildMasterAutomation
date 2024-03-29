
#Requires -Version 5.1

BeforeAll {
    Set-StrictMode -Version 'Latest'

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
        $freshApp = $appName | Get-BMApplication -Session $script:session
        $freshApp | Should -Not -BeNullOrEmpty
        $freshApp.Application_Id | Should -Be $app.Application_Id
    }

    It 'should fail if application exists' {
        $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
        New-BMApplication -Session $script:session -Name $appName
        $app2 = New-BMApplication -Session $script:session -Name $appName -ErrorAction SilentlyContinue
        $Global:Error | Should -Match 'already exists'
        $app2 | Should -BeNullOrEmpty
    }

    It 'should set values for all parameters' {
        $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
        $app = New-BMApplication -Session $script:session `
                                 -Name $appName `
                                 -ReleaseNumberSchemeName DateBased `
                                 -BuildNumberSchemeName DateTimeBased
        $app | Should -Not -BeNullOrEmpty
        $app.ReleaseNumber_Scheme_Name | Should -Be 'DateBased'
        $app.BuildNumber_Scheme_Name | Should -Be 'DateTimeBased'
    }

    It 'should create application in an application group' {
        $appGroupID = Invoke-BMNativeApiMethod -Session $script:session `
                                               -Name 'ApplicationGroups_GetOrCreateApplicationGroup' `
                                               -Parameter @{ ApplicationGroup_Name = 'TestBMAppGroup' } `
                                               -Method Post
        $appName = ('New-BMApplication.{0}' -f [IO.Path]::GetRandomFileName())
        $app = New-BMApplication -Session $script:session -Name $appName -ApplicationGroup $appGroupID
        $app | Should -Not -BeNullOrEmpty
        $app.ApplicationGroup_Name | Should -Be 'TestBMAppGroup'
    }

    It 'should set application''s raft' {
        $name = New-BMTestObjectName
        $raft = Set-BMRaft -Session $script:session -Raft $name -PassThru
        $app = New-BMApplication -Session $script:session -Name $name -Raft $raft
        $app.Raft_Name | Should -Be $name
    }
}
