
function ConvertTo-BMOtterScriptExpression
{
    <#
    .SYNOPSIS
    Converts a PowerShell object into an OtterScript expression.

    .DESCRIPTION
    The `ConvertTo-BMOtterScriptExpression` function takes a PowerShell object as an input and returns a representation
    of the object in OtterScript. This function converts .NET IEnumerable and IDictionary  objects to OtterScript vector
    and map types respectively.

    .LINK
    https://docs.inedo.com/docs/executionengine-otterscript-strings-and-literals

    .EXAMPLE
    ,@(1, 2, 3, 4) | ConvertTo-BMOtterScriptExpression

    Demonstrates turning an IEnumerable of PowerShell integers into an array of OtterScript integers. Output will be
    `@(1, 2, 3, 4)`

    .EXAMPLE
    @{ 'hello' = 'world'; 'goodbye' = 'world' } | ConvertTo-BMOtterScriptExpression

    Demonstrates turning a PowerShell IDictionary into an OtterScript map. Output will be `%(hello: world, goodbye: world)`
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
        $isDict = $Value -is [System.Collections.IDictionary]
        $isList = $Value -is [System.Collections.IEnumerable] -and $Value -is [System.Collections.ICollection]

        if ($Value -is [String] -or $Value -is [Int])
        {
            return $Value.ToString()
        }

        if (-not $isDict -and -not $isList)
        {
            $valueType = ($Value | Get-Member).TypeName | Select-Object -Unique
            $msg = "Unable to convert '${valueType}' to OtterScript expression. All values must either inherit " +
                   'the IDictionary or the IEnumarable interface or be of type String or Int.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        if ($isDict)
        {
            $mapExpression = '%('
            $sortedKeys = $Value.Keys | Sort-Object
            foreach ($key in $sortedKeys)
            {
                if ($Value[$key] -is [System.Collections.ICollection])
                {
                    $Value[$key] = ConvertTo-BMOtterScriptExpression -Value $Value[$key]
                }
                $mapExpression += "${key}: $($Value[$key]), "
            }

            $mapExpression = $mapExpression -replace ', $'
            $mapExpression += ')'
            return $mapExpression
        }

        $result = & {
            foreach ($item in $Value)
            {
                if ($item -is [System.Collections.ICollection])
                {
                    $item = ConvertTo-BMOtterScriptExpression -Value $item
                    $item | Write-Output
                    continue
                }

                $item | Write-Output
            }
        }
        return "@($($result -join ', '))"
    }
}
