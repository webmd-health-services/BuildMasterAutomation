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
    ,@(1, 2, 3, 4) | ConvertTo-BMOtterScriptExpression

    Demonstrates turning an array of PowerShell integers into an array of OtterScript integers. Output will be
    `$(1, 2, 3, 4)`

    .EXAMPLE
    @{ 'hello' = 'world'; 'goodbye' = 'world' } | ConvertTo-BMOtterScriptExpression

    Demonstrates turning a PowerShell hashmap into an OtterScript map. Output will be `%(hello: world, goodbye: world)`
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Value
    )

    process {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($Value -is [array])
        {
            foreach ($item in $Value)
            {
                if ($item -is [hashtable] -or $item -is [array])
                {
                    $msg = 'Unable to convert array to OtterScript expression. OtterScript does not support nested ' +
                           'objects.'
                    Write-Warning $msg
                    return ($Value | ConvertTo-Json)
                }
            }
            return "@($($Value -join ', '))"
        }

        if (-not $Value -is [hashtable])
        {
            return $Value
        }

        $mapExpression = '%('
        foreach ($key in $Value.Keys)
        {
            if ($Value[$key] -is [hashtable] -or $Value[$key] -is [array])
            {
                $msg = 'Unable to convert hashtable to OtterScript expression. OtterScript does not support nested ' +
                        'objects.'
                Write-Warning $msg
                return ($Value | ConvertTo-Json)
            }

            $mapExpression += "${key}: $($Value[$key]), "
        }

        $mapExpression = $mapExpression -replace ', $'
        $mapExpression += ')'
        return $mapExpression
    }
}