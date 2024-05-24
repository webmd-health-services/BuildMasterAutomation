Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    function GivenValue
    {
        param(
            [string] $Value
        )

        $script:value = $Value
    }

    function WhenConverting
    {
        $script:result = ConvertFrom-BMOtterScriptExpression -Value $script:value
    }

    function ThenEqual
    {
        param(
            [Parameter(Mandatory)]
            $Expected,
            $Result
        )

        if (-not $Result)
        {
            $Result = $script:result
        }

        if ($Result -is [hashtable])
        {
            foreach ($item in $Result.Keys)
            {
                $e = $Expected[$item]
                if ($item -is [int64])
                {
                    $e = $Expected[[Convert]::ToInt32($item)]
                }
                $r = $Result[$item]

                ThenEqual -Result $r -Expected $e
            }
        }
        elseif ($Result -is [array])
        {
            for ($i = 0; $i -lt $Result.Length; $i++)
            {
                if (($Result[$i] -is [hashtable] -and $Result[$i].Count -eq 0) -or
                    ($Result[$i] -is [array] -and $Result[$i].Length -eq 0))
                {
                    continue
                }
                ThenEqual -Result $Result[$i] -Expected $Expected[$i]
            }
        }
        else
        {
            $Result | Should -Be $Expected -Because "${Result} should be ${Expected}"
        }
    }
}

Describe 'ConvertFrom-BMOtterScriptExpression' {
    BeforeEach {
        $script:result = $null
        $script:value = $null
    }

    It 'should return an array' {
        GivenValue '@(one, two, three)'
        WhenConverting
        ThenEqual -Expected 'one', 'two', 'three'
    }

    It 'should return a map' {
        GivenValue '%(hello: world, hi: there)'
        WhenConverting
        ThenEqual -Expected @{'hello' = 'world'; 'hi' = 'there'}
    }

    It 'should support spaces inside of arrays' {
        GivenValue '@(this is one entry, this is another one, two, three)'
        WhenConverting
        ThenEqual -Expected 'this is one entry', 'this is another one', 'two', 'three'
    }

    It 'should support spaces inside of maps keys and values' {
        GivenValue '%(hello: this is a value, goodbye world: just kidding)'
        WhenConverting
        ThenEqual -Expected @{'hello' = 'this is a value'; 'goodbye world' = 'just kidding'}
    }

    It 'should automatically convert numbers in maps' {
        GivenValue '%(1: two, three: 4)'
        WhenConverting
        ThenEqual -Expected @{1 = 'two'; 'three' = 4}
    }

    It 'should automatically convert numbers in vectors' {
        GivenValue '@(1, 2, 3, 4, 5, 6)'
        WhenConverting
        ThenEqual -Expected 1, 2, 3, 4, 5, 6
    }

    It 'should support nested vectors' {
        GivenValue '@(1, 2, 3, @(4, @(5, 6), @(7, 8)))'
        WhenConverting
        ThenEqual @(1, 2, 3, @(4, @(5, 6), @(7, 8)))
    }

    It 'should support nested maps' {
        GivenValue '%(first: %(second: %(third: %(fourth: level))))'
        WhenConverting
        ThenEqual @{'first' = @{'second' = @{'third' = @{'fourth' = 'level'}}}}
    }

    It 'should support maps inside of vectors and vice versa' {
        GivenValue '@(one, %(hello: @(two, three, four)), five)'
        WhenConverting
        ThenEqual @('one', @{'hello' = @('two', 'three', 'four')}, 'five')
    }

    It 'should return as a string if not valid syntax' {
        GivenValue '@(one, two'
        WhenConverting
        ThenEqual '@(one, two'
        GivenValue 'three'
        WhenConverting
        ThenEqual 'three'
        GivenValue '%(five, six'
        WhenConverting
        ThenEqual '%(five, six'
        GivenValue '%(seven, eight))'
        WhenConverting
        ThenEqual '%(seven, eight))'
    }

    It 'should convert if map is first element in vector' {
        GivenValue '@(%(one: 1), two)'
        WhenConverting
        ThenEqual @( @{ 'one' = 1 }, 'two')
    }

    It 'should allow for strings that are surrounded by parens' {
        GivenValue '(this is a string)'
        WhenConverting
        ThenEqual '(this is a string)'
    }

    It 'should support empty objects' {
        GivenValue '@(@(), @())'
        WhenConverting
        ThenEqual @(@(), @())

        GivenValue '@(%(), %())'
        WhenConverting
        ThenEqual @(@{}, @{})

        GivenValue ''
        WhenConverting
        ThenEqual ''
    }
}
