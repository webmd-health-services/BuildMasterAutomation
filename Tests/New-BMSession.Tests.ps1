
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)
}

Describe 'New-BMSession' {
    It 'should return a session object' {
        $url = 'https://fubar.snafu'
        $key = 'fubarsnafu'

        $session = New-BMSession -Url $url -ApiKey $key
        $session | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be ([uri]$url)
        $session.ApiKey | Should -Be $key
    }
}