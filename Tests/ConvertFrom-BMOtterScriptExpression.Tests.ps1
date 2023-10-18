#Requires -Version 5.1
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
        $script:result = ConvertFrom-BMOtterScriptExpression -Value $script:value -WarningVariable 'warnings'
        $script:warnings = $warnings
    }

    function ThenIsString
    {
        $script:result | Should -BeOfType [string]
    }

    function ThenIsMap
    {
        $script:result | Should -BeOfType [hashtable]
    }

    function ThenIsVector
    {
        ,$script:result | Should -BeOfType [array]
    }

    function ThenEquals
    {
        param(
            $Value
        )

        $script:result | Should -Be $Value
    }

    function ThenMapEquals {
        param(
            [hashtable] $Value
        )

        foreach ($key in $script:result.Keys)
        {
            $script:result[$key] | Should -Be $Value[$key]
        }

        foreach ($key in $Value.Keys)
        {
            $script:result[$key] | Should -Be $Value[$key]
        }
    }
}

Describe 'ConvertFrom-BMOtterScriptExpression' {
    BeforeEach {
        $script:value = $null
        $script:result = $null
    }

    It 'should convert otterscript vector to array' {
        GivenValue '@(hello, there, my friend)'
        WhenConverting
        ThenIsVector
        ThenEquals 'hello', 'there', 'my friend'
    }

    It 'should leave non-string values as strings' {
        GivenValue '@(hello, 1, 2, 3, 4)'
        WhenConverting
        ThenIsVector
        ThenEquals 'hello', '1', '2', '3', '4'
    }

    It 'should convert otterscript map to hashtable' {
        GivenValue '%(one: two, three: four)'
        WhenConverting
        ThenIsMap
        ThenMapEquals @{ 'one' = 'two'; 'three' = 'four' }
    }

    It 'should leave non-string values as strings' {
        GivenValue '%(1: one, 2: two)'
        WhenConverting
        ThenIsMap
        ThenMapEquals @{ '1' = 'one'; '2' = 'two' }
    }

    It 'should return string representation' {
        GivenValue 'hi this is a string'
        WhenConverting
        ThenIsString
        ThenEquals 'hi this is a string'
    }
}