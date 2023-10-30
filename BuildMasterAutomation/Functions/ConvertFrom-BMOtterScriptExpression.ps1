
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
        # The OtterScript expression to convert to a PowerShell object.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $Value
    )

    begin {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        function ConvertTo-Int
        {
            param(
                [Parameter(Mandatory)]
                [String] $Item
            )

            $maybeInt = 0
            if (([Int64]::TryParse($Item, [ref] $maybeInt)))
            {
                return $maybeInt
            }

            return $Item
        }
    }

    process {
        $isMap = $Value.StartsWith('%(') -and $Value.EndsWith(')')
        $isVector = $Value.StartsWith('@(') -and $Value.EndsWith(')')
        $originalValue = $Value

        if (-not $isMap -and -not $isVector)
        {
            return ConvertTo-Int -Item $Value.Trim()
        }

        if ($isMap)
        {
            $Value = $Value -replace '^%\('
        }
        else
        {
            $Value = $Value -replace '^@\('
        }

        $Value = $Value -replace '\)$'

        $closesNeeded = 0
        # Splitting up array or map by comma and collecting into array.
        $parsedItems = &{
            $start = 0
            $end = 0
            foreach ($i in 0..($Value.Length - 1))
            {
                $char = $Value[$i]

                if ($char -eq '(' -and ($Value[$i - 1] -eq '@' -or $Value[$i - 1] -eq '%'))
                {
                    $closesNeeded++
                    continue
                }

                if ($char -eq ')' -and $closesNeeded)
                {
                    $closesNeeded--
                    if ($i -ne ($Value.Length - 1))
                    {
                        continue
                    }
                }

                if ($closesNeeded)
                {
                    continue
                }

                if ($char -ne ',' -and $i -ne ($Value.Length - 1))
                {
                    continue
                }

                $end = $i
                $lengthOfSubstring = $end - $start

                if ($i -eq ($Value.Length - 1))
                {
                    $lengthOfSubstring++
                }

                $entry = $Value.Substring($start, $lengthOfSubstring).Trim()
                $entry | Write-Output
                $start = $i + 1
            }
        }

        if ($closesNeeded)
        {
            return $originalValue
        }

        if ($isVector)
        {
            $parsedItems = $parsedItems | ForEach-Object { ConvertFrom-BMOtterScriptExpression -Value $_ }
            return ,$parsedItems
        }

        $map = @{}

        # Splitting each item by ':' to determine keys and values
        foreach ($kvpair in $Value -split ',')
        {
            $substringLength = 0
            foreach ($i in 0..($kvpair.Length - 1))
            {
                if ($kvpair[$i] -eq ':')
                {
                    $substringLength = $i
                    break
                }
            }
            $key = ConvertTo-Int -Item $kvpair.Substring(0, $substringLength).Trim()
            $value = ConvertFrom-BMOtterScriptExpression -Value ($kvpair.Substring($substringLength + 1).Trim())
            $map[$key] = $value
        }
        return ,$map
    }
}