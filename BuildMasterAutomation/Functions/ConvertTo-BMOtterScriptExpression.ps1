
function ConvertTo-BMOtterScriptExpression
{
    <#
    .SYNOPSIS
    Converts a PowerShell object into an OtterScript expression.

    .DESCRIPTION
    The `ConvertTo-BMOtterScriptExpression` function takes a PowerShell object as an input and returns a representation
    of the object in OtterScript. This function converts PowerShell arrays and hashtables to OtterScript vector and map
    types respectively.

    .LINK
    https://docs.inedo.com/docs/executionengine-otterscript-strings-and-literals

    .EXAMPLE
    ,@(1, 2, 3, 4) | ConvertTo-BMOtterScriptExpression

    Demonstrates turning an array of PowerShell integers into an array of OtterScript integers. Output will be
    `@(1, 2, 3, 4)`

    .EXAMPLE
    @{ 'hello' = 'world'; 'goodbye' = 'world' } | ConvertTo-BMOtterScriptExpression

    Demonstrates turning a PowerShell hashtable into an OtterScript map. Output will be `%(hello: world, goodbye: world)`
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Value
    )

    begin {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {

        if ($Value -is [array])
        {

            $Value = & {
                foreach ($item in $Value)
                {
                    if ($item -is [hashtable] -or $item -is [array])
                    {
                        ConvertTo-BMOtterScriptExpression -Value $item | Write-Output
                        continue
                    }

                    $item | Write-Output
                }
            }
            return "@($($Value -join ', '))"
        }

        if (-not ($Value -is [hashtable]))
        {
            return $Value
        }

        $mapExpression = '%('
        $sortedKeys = $Value.Keys | Sort-Object -Descending
        foreach ($key in $sortedKeys)
        {
            if ($Value[$key] -is [hashtable] -or $Value[$key] -is [array])
            {
                $Value[$key] = ConvertTo-BMOtterScriptExpression -Value $item
            }
            $mapExpression += "${key}: $($Value[$key]), "
        }

        $mapExpression = $mapExpression -replace ', $'
        $mapExpression += ')'
        return $mapExpression
    }
}
