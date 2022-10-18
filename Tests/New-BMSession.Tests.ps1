
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)
}

Describe 'New-BMSession' {
    It 'should return a session object' {
        $uri = 'https://fubar.snafu'
        $key = 'fubarsnafu'

        $session = New-BMSession -Uri $uri -ApiKey $key
        $session | Should -Not -BeNullOrEmpty
        $session.Uri | Should -Be ([uri]$uri)
        $session.ApiKey | Should -Be $key
    }
}