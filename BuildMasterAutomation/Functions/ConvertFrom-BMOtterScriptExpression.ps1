
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
    "%(hello: %(hi: world))" | ConvertFrom-BMOtterScriptExpression

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

        function Edit-Output
        {
            param(
                [Parameter(Mandatory, ValueFromPipeline)]
                $InputObject
            )

            $InputObject = $InputObject.Trim()

            $maybeInt = 0
            if (([Int64]::TryParse($InputObject, [ref] $maybeInt)))
            {
                return $maybeInt
            }

            return $InputObject
        }
    }

    process {
        $originalValue = $Value
        $Value = $Value.Trim()

        $isMap = $Value.StartsWith('%(') -and $Value.EndsWith(')')
        $isVector = $Value.StartsWith('@(') -and $Value.EndsWith(')')
        $isScalar = -not $isMap -and -not $isVector

        if ($isScalar)
        {
            if ($Value.StartsWith('@(') -or $Value.StartsWith('%('))
            {
                $msg = "Unable to convert '${originalValue}' to a PowerShell Object because of invalid syntax. " +
                       'Returning original value.'
                Write-Warning -Message $msg
            }
            return $Value | Edit-Output
        }

        $Value = $Value -replace '\)$'

        if ($isMap)
        {
            $Value = $Value -replace '^%\('
            if (-not $Value)
            {
                return @{}
            }
        }
        else
        {
            $Value = $Value -replace '^@\('
            if (-not $Value)
            {
                return ,@()
            }
        }

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

                if ($closesNeeded -or ($char -ne ',' -and $i -ne ($Value.Length - 1)))
                {
                    continue
                }

                $end = $i
                $lengthOfSubstring = $end - $start

                if ($i -eq ($Value.Length - 1))
                {
                    $lengthOfSubstring++
                }

                $Value.Substring($start, $lengthOfSubstring).Trim() | Write-Output
                $start = $i + 1
            }
        }

        $invalidSyntax = $closesNeeded -gt 0

        if ($isMap)
        {
            foreach ($mapItem in $parsedItems)
            {
                if  ($mapItem -notmatch '^[\w\d\s\-]+:')
                {
                    $invalidSyntax = $true
                    break
                }
            }
        }

        if ($invalidSyntax)
        {
            $msg = "Unable to convert '${originalValue}' to a PowerShell Object because of invalid syntax. " +
                   'Returning original value.'
            Write-Warning -Message $msg
            return $originalValue | Edit-Output
        }

        if ($isVector)
        {
            return ,@($parsedItems | ConvertFrom-BMOtterScriptExpression)
        }

        $hashtable = @{}

        foreach ($kvpair in $parsedItems)
        {
            $colonIndex = $kvpair.IndexOf(':')
            $mapKey = $kvpair.Substring(0, $colonIndex) | Edit-Output
            $mapValue = $kvpair.Substring($colonIndex + 1) | ConvertFrom-BMOtterScriptExpression

            $hashtable[$mapKey] = $mapValue
        }

        return $hashtable
    }
}