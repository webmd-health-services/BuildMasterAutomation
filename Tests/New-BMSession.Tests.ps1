
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

Describe 'New-BMSession.when passed parameters' {
    $uri = 'https://fubar.snafu'
    $key = 'fubarsnafu'

    $session = New-BMSession -Uri $uri -ApiKey $key

    It 'should return session object' {
        $session | Should Not BeNullOrEmpty
    }

    It 'should set URI' {
        $session.Uri | Should Be ([uri]$uri)
    }

    It 'should set API key' {
        $session.ApiKey | Should Be $key
    }
}