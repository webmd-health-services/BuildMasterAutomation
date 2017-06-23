
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession 
$app = New-BMTestApplication -Session $session -CommandPath $PSCommandPath
$pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())
$pipeline = New-BMPipeline -Session $session -Name $pipelineName -Application $app -Color '#ffffff'
$develop = New-BMRelease -Session $session -Application $app -Number '1.0' -Pipeline $pipeline -Name 'develop'
$release = New-BMRelease -Session $session -Application $app -Number '2.0' -Pipeline $pipeline -Name 'release'
$master = New-BMRelease -Session $session -Application $app -Number '3.0' -Pipeline $pipeline -Name 'master'

Describe 'Get-BMRelease.when getting an application''s releases' {
    $release = Get-BMRelease -Session $session -Application $app | Sort-Object -Property 'id'

    It 'should return releases' {
        $release | Should -Not -BeNullOrEmpty
        $release.Count | Should -Be 3
        $release[0].number | Should -Be '1.0'
        $release[1].number | Should -Be '2.0'
        $release[2].number | Should -Be '3.0'
    }
}

Describe 'Get-BMRelease.when getting an application release by name' {
    $release = Get-BMRelease -Session $session -Application $app -Name 'develop'

    It 'should return release' {
        $release | Should -Not -BeNullOrEmpty
        $release.name | Should -Be 'develop'
    }
}

Describe 'Get-BMRelease.when passed no parameters' {
    $releases = Get-BMRelease -Session $session

    It 'should return all releases' {
        $releases | Where-Object { $_.id -eq $develop.id } | Should -Not -BeNullOrEmpty
        $releases | Where-Object { $_.id -eq $release.id } | Should -Not -BeNullOrEmpty
        $releases | Where-Object { $_.id -eq $master.id } | Should -Not -BeNullOrEmpty
    }
}