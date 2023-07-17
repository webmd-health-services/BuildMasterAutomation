
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $defaultObjectName = New-BMTestObjectName
    $raft = Set-BMRaft -Session $script:session -Raft $defaultObjectName -PassThru
    $script:app = New-BMApplication -Session $script:session -Name $defaultObjectName -Raft $raft
    $pipeline = Set-BMPipeline -Session $script:session `
                               -Name $defaultObjectName `
                               -Application $script:app `
                               -Color '#ffffff' `
                               -PassThru
    $script:develop = New-BMRelease -Session $script:session `
                                    -Application $script:app `
                                    -Number '1.0' `
                                    -Pipeline $pipeline `
                                    -Name 'develop'
    $script:release = New-BMRelease -Session $script:session `
                                    -Application $script:app `
                                    -Number '2.0' `
                                    -Pipeline $pipeline `
                                    -Name 'release'
    $script:master = New-BMRelease -Session $script:session `
                                   -Application $script:app `
                                   -Number '3.0' `
                                   -Pipeline $pipeline `
                                   -Name 'script:master'
}

Describe 'Get-BMRelease' {
    It 'should return releases by application' {
        $release = Get-BMRelease -Session $script:session -Application $script:app | Sort-Object -Property 'id'
        $release | Should -Not -BeNullOrEmpty
        $release.Count | Should -Be 3
        $release[0].number | Should -Be '1.0'
        $release[1].number | Should -Be '2.0'
        $release[2].number | Should -Be '3.0'
    }

    It 'should return release by name' {
        $release = 'develop' | Get-BMRelease -Session $script:session -Application $script:app
        $release | Should -Not -BeNullOrEmpty
        $release.name | Should -Be 'develop'
    }

    It 'should return all releases' {
        $releases = Get-BMRelease -Session $script:session
        $releases | Where-Object { $_.id -eq $script:develop.id } | Should -Not -BeNullOrEmpty
        $releases | Where-Object { $_.id -eq $script:release.id } | Should -Not -BeNullOrEmpty
        $releases | Where-Object { $_.id -eq $script:master.id } | Should -Not -BeNullOrEmpty
    }
}
