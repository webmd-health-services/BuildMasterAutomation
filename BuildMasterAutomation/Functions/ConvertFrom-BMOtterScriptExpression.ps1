
function ConvertFrom-BMOtterScriptExpression
{
    <#
    .SYNOPSIS
    Converts an Otterscript expression into a PowerShell object.

    .DESCRIPTION
    The `ConvertFrom-BMOtterScriptExpression` function takes an OtterScript expression as an input and converts it into
    a PowerShell representation of the object. This function supports converting both `vector` and `map` types into
    their respective `array` and `hashtable` types in PowerShell.

    .LINK
    https://docs.inedo.com/docs/executionengine-otterscript-strings-and-literals

    .EXAMPLE
    "@(1, 2, 3, 4)" | ConvertFrom-BMOtterScriptExpression

    Demonstrates converting an OtterScript vector into a PowerShell array.

    .EXAMPLE
    "%(hello: world)" | ConvertFrom-BMOtterScriptExpression

    Demonstrates converting an OtterScript map into a PowerShell hashtable.

    .EXAMPLE
    "%(hello: %(hi: world))" | ConvertFrom-BMOtterSCriptExpression

    Demonstrates converting nested OtterScript maps into nested PowerShell hashtables.

    .EXAMPLE
    "@(1, 2, @(3, 4))" | ConvertFrom-BMOtterScriptExpression

    Demonstrates converting nested OtterScript vectors into nested PowerShell arrays.

    .EXAMPLE
    "@(1, 2, %(hello: world, hi there: @(5, 6, 7)))" | ConvertFrom-BMOtterScriptExpression

    Demonstrates converting nested OtterScript vectors and maps into nested PowerShell arrays and hashtables.
    #>
    [CmdletBinding()]
    param(
        # The string to parse into a PowerShell expression
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $Value,
        [int] $Depth = 0
    )

    begin {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        function ConvertTo-Int
        {
            param(
                [Parameter(Mandatory)]
                [String] $Current
            )

            $current = $Current.Trim()
            $maybeInt = 0
            if (([Int64]::TryParse($current, [ref] $maybeInt)))
            {
                return $maybeInt
            }

            return $current
        }
    }

    process {
        $isMap = $Value.StartsWith('%(') -and $Value.EndsWith(')')
        $isVector = $Value.StartsWith('@(') -and $Value.EndsWith(')')

        if (-not $isMap -and -not $isVector)
        {
            return $Value
        }

        $Value = $Value -replace '^@\(' -replace '^%\(' -replace '\)$'
        $index = 0
        $stack = [System.Collections.Stack]::New()
        $nestedStore = @{}
        while ($index -lt $Value.Length)
        {
            if (($Value[$index] -eq '@' -or $Value[$index] -eq '%')-and $Value[$index + 1] -eq '(')
            {
                $stack.Push($index)
                $index++
            }

            if ($Value[$index] -ne ')')
            {
                $index++
                continue
            }

            $lastItem = $stack.Pop()
            if ($stack.Count -ne 0)
            {
                $index++
                continue
            }

            $keyName = "PLACEHOLDER_$($nestedStore.Count)"
            $nestedStore[$keyName] = ConvertFrom-BMOtterScriptExpression -Value ($Value.Substring($lastItem, $index - $lastItem + 1)) -Depth ($Depth + 1)
            $Value = $Value.Remove($lastItem, $index - $lastItem + 1)
            $Value = $Value.Insert($lastItem, $keyName)
            $Index = $lastItem + $keyName.Length
            $index++
        }

        if ($isVector)
        {
            $arr = $Value -split ',' | ForEach-Object {
                    $x = $_.Trim()
                    if ($nestedStore[$x])
                    {
                        Write-Debug "$($nestedStore[$x] | ConvertTo-Json)"
                        return ,($nestedStore[$x])
                    }
                    return ConvertTo-Int $x
                }
            return $arr
        }

        $map = @{}
        foreach ($kvpair in $Value -split ',')
        {
            $kv = $kvpair -split ':' | ForEach-Object { $_.Trim() }
            $key = ConvertTo-Int $kv[0]
            $value = $kv[1]
            $map[$key] = ConvertTo-Int $value
            if ($nestedStore[$value])
            {
                $map[$key] = $nestedStore[$value]
            }
        }
        return $map
    }
}

# $result = ConvertFrom-BMOtterScript "@(1, 2, 3, 4)" | Write-Output
# $result | ConvertTo-Json | Write-Output
# #
# $result = ConvertFrom-BMOtterScript "@(1, 2, @(3, 4), @(5, 6), @(7, 8))"
# $result | ConvertTo-Json | Write-Output

# $result = ConvertFrom-BMOtterScript "@(1, 2, @(3, 4, @(5, 6)))"
# $result | ConvertTo-Json | Write-Output

# $result = ConvertFrom-BMOtterScript "@(1, 2, @(3, 4, @(5, 6)), @(1, 2, @(3, 4)))"
# $result | ConvertTo-Json | Write-Output

# $result = ConvertFrom-BMOtterScript "@(1, 2, %(hello: world, hi: @(1, 2, 3, 4)))"
# $result | ConvertTo-Json | Write-Output