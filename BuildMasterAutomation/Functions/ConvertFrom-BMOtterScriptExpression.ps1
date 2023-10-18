function ConvertFrom-BMOtterScriptExpression
{
    <#
    .SYNOPSIS
    Converts an OtterScript expression into a PowerShell object.

    .DESCRIPTION
    The `ConvertFrom-BMOtterScriptExpression` function takes an OtterScript string as an input and converts it into a
    PowerShell representation of the object. This function supports converting both `vector` and `maps` types into their
    respective `array` and `hashtable` types in PowerShell.

    Note: This function will leave all values as strings when converting from OtterScript to Powershell.

    .LINK
    https://docs.inedo.com/docs/executionengine-otterscript-strings-and-literals

    .EXAMPLE
    "$(1, 2, 3, 4)" | ConvertFrom-BMOtterScriptExpression

    Demonstrates converting an OtterScript vector into a PowerShell array.

    .EXAMPLE
    "%(hello: world)" | ConvertFrom-BMOtterScriptExpression

    Demonstrates converting an OtterScript map into a PowerShell hashtable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Value
    )

    process {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($Value.StartsWith("@(") -and $Value.EndsWith(')'))
        {
            $val = $Value -replace '^@\(' -replace '\)$' -split ',' | ForEach-Object { $_.Trim() }
            return $val
        }

        if ($Value.StartsWith("%(") -and $Value.EndsWith(')'))
        {
            $kvPairs = $Value -replace '^%\(' -replace '\)$' -split ',' | ForEach-Object { $_.Trim() }
            $table = @{}
            foreach ($pair in $kvPairs)
            {
                $kv = $pair -split ':' | ForEach-Object { $_.Trim() }
                $table[$kv[0]] = $kv[1]
            }
            return $table
        }

        return $Value
    }
}