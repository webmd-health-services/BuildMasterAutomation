Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    function GivenValue
    {
        param(
            $Value
        )

        $script:value = $Value
    }

    function WhenConverting
    {
        $warnings = @()
        $script:result = ConvertTo-BMOtterScriptExpression -Value $script:value -WarningVariable 'warnings'
        $script:warnings = $warnings
    }

    function ThenIsJson
    {
        $script:result | ConvertFrom-Json
    }

    function ThenIsMap
    {
        $script:result.StartsWith('%(') | Should -BeTrue
        $script:result.EndsWith(')') | Should -BeTrue
    }

    function ThenIsVector
    {
        $script:result.StartsWith('@(') | Should -BeTrue
        $script:result.EndsWith(')') | Should -BeTrue
    }

    function ThenEquals
    {
        param(
            $Value
        )

        $script:result | Should -Be $Value
    }

    function ThenWarn
    {
        param(
            $Message
        )

        $script:warnings | Should -Not -BeNullOrEmpty
        $script:warnings | Should -HaveCount 1
        $script:warnings | Select-Object -First 1 | Should -BeLike $Message
    }
}

Describe 'ConvertTo-BMOtterScriptExpression' {
    BeforeEach {
        $script:value = $null
        $script:result = $null
        $script:warnings = $null
    }

    It 'should result in a string map' {
        GivenValue @{ 'hello' = 'world'; 'goodbye' = 'world' }
        WhenConverting
        ThenIsMap
        ThenEquals '%(hello: world, goodbye: world)'
    }

    It 'should result in a map of mixed types' {
        GivenValue @{ 1 = 'hi'; 1.1 = 'bye' }
        WhenConverting
        ThenIsMap
        ThenEquals '%(1: hi, 1.1: bye)'
    }

    It 'should return a vector' {
        GivenValue 'hello', 'there', 'my', 'friend'
        WhenConverting
        ThenIsVector
        ThenEquals '@(hello, there, my, friend)'
    }

    It 'should return multi-type vector' {
        GivenValue 1, 'hi', 2.2, 'there'
        WhenConverting
        ThenIsVector
        ThenEquals '@(1, hi, 2.2, there)'
    }

    It 'should return json' {
        GivenValue @{ '1' = 'hi'; '2' = @{ 'hello' = 'world'}; '3' = @(1, 2, 3) }
        WhenConverting
        ThenIsJson
        ThenWarn 'Unable to convert hashtable*'
    }

    It 'should return json' {
        GivenValue @(1, 2, 3, @(4, 5, 6))
        WhenConverting
        ThenIsJson
        ThenWarn 'Unable to convert array*'
    }
}