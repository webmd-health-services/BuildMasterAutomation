
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:app = New-BMTestApplication -Session $script:session -CommandPath $PSCommandPath
    $script:pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())
    $script:pipeline = Set-BMPipeline -Session $script:session `
                                      -Name $script:pipelineName `
                                      -Application $script:app `
                                      -Color '#ffffff' -PassThru
    $script:develop = New-BMRelease -Session $script:session `
                                    -Application $script:app `
                                    -Number '1.0' `
                                    -Pipeline $script:pipeline `
                                    -Name 'script:develop'
    $script:release = New-BMRelease -Session $script:session `
                                    -Application $script:app `
                                    -Number '2.0' `
                                    -Pipeline $script:pipeline `
                                    -Name 'release'
    $script:master = New-BMRelease -Session $script:session `
                                   -Application $script:app `
                                   -Number '3.0' `
                                   -Pipeline $script:pipeline `
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
        $release = Get-BMRelease -Session $script:session -Application $script:app -Name 'script:develop'
        $release | Should -Not -BeNullOrEmpty
        $release.name | Should -Be 'script:develop'
    }

    It 'should return all releases' {
        $releases = Get-BMRelease -Session $script:session
        $releases | Where-Object { $_.id -eq $script:develop.id } | Should -Not -BeNullOrEmpty
        $releases | Where-Object { $_.id -eq $script:release.id } | Should -Not -BeNullOrEmpty
        $releases | Where-Object { $_.id -eq $script:master.id } | Should -Not -BeNullOrEmpty
    }
}
