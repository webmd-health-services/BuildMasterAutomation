function ConvertTo-BMOtterScriptExpression
{
    <#
    .SYNOPSIS
    Converts a PowerShell object into an OtterScript expression.

    .DESCRIPTION
    The `ConvertTo-BMOtterScriptExpression` function takes a PowerShell object as an input and returns a representation
    of the object in OtterScript. This function supports converting both `hastable` and `array` types into their
    respective OtterScript versions.

    OtterScript does not support nested objects so the provided expression must be made up completely of literal
    objects. If the provided expression cannot be converted to an OtterScript native type, then the string
    representation will be returned in JSON.

    .LINK
    https://docs.inedo.com/docs/executionengine-otterscript-strings-and-literals

    .EXAMPLE
    1, 2, 3, 4 | ConvertTo-BMOtterScriptExpression

    Demonstrates turning an array of PowerShell integers into an array of OtterScript integers. Output will be
    `$(1, 2, 3, 4)`

    .EXAMPLE
    { 'hello' = 'world'; 'goodbye' = 'world' } | ConvertTo-BMOtterScriptExpression

    Demonstrates turning a PowerShell hashmap into an OtterScript map. Output will be `%(hello: world, goodbye: world)`
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Expression
    )

    process {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($Expression -is [hashtable])
        {
            $mapExpression = '%('
            foreach ($key in $Expression.Keys)
            {
                if ($Expression[$key] -is [hashtable] -or $Expression[$key] -is [array])
                {
                    Write-Warning "Unable to convert hashtable to OtterScript expression. OtterScript does not support nested objects."
                    return ($Expression | ConvertTo-Json)
                }

                $mapExpression += "${key}:$($Expression[$key]),"
            }

            $mapExpression = $mapExpression -replace ',$'
            $mapExpression += ')'
            $mapExpression | Write-Output
        }
        elseif ($Expression -is [array])
        {
            foreach ($item in $Expression)
            {
                if ($item -is [hashtable] -or $item -is [array])
                {
                    Write-Warning "Unable to convert array to OtterScript expression. OtterScript does not support nested objects."
                    return ($Expression | ConvertTo-Json)
                }
            }
            "@($($Expression -join ','))" | Write-Output
        }
        else
        {
            $Expression | Write-Output
        }
    }
}