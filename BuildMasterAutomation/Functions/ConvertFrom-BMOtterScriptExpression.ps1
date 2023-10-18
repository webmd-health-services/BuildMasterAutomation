function ConvertFrom-BMOtterScriptExpression
{
    <#
    .SYNOPSIS
    Converts an OtterScript expression into a PowerShell object.

    .DESCRIPTION
    The `ConvertFrom-BMOtterScriptExpression` function takes an OtterScript string as an input and converts it into a
    PowerShell representation of the object. This function supports converting both `vector` and `maps` types into their
    respective `array` and `hashtable` types in PowerShell.

    .LINK
    https://docs.inedo.com/docs/executionengine-otterscript-strings-and-literals

    .EXAMPLE
    "$(1, 2, 3, 4)" | ConvertFrom-BMOtterScriptExpression

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Value
    )
    process {

        if ($Value.StartsWith("@("))
        {
            $val = $Value.Replace('^@(', '').Replace(')$', '') -split ',' | ForEach-Object { $_.Trim }
            return $val
        }

        if ($Value.StartsWith("%("))
        {
            $kvPairs = $Value.Replace('^%(', '').Replace(')$', '') -split ','
            $table = @{}
            foreach ($pair in $kvPairs)
            {
                $kv = $pair -split ':' | ForEach-Object { $_.Trim }
                $table[$kv[0]] = $kv[1]
            }
            return $table
        }

        return $Value
    }
}