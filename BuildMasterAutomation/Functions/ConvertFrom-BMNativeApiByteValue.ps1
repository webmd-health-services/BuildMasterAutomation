
function ConvertFrom-BMNativeApiByteValue
{
    <#
    .SYNOPSIS
    Converts a binary value returned from the BuildMaster native API as a `byte[]` object to a string.

    .DESCRIPTION
    Some of the objects returned by the BuildMaster native API have properties that are typed as byte arrays, i.e.
    `byte[]`.This function converts these values into strings. Pipe the value to the function (or pass it to the
    `InputObject` parameter).

    .EXAMPLE
    ConvertFrom-BMNativeApiByteValue 'ZW1wdHk='

    Demonstrates how to convert a `byte[]` value returned by a BuildMaster native API into its original string/text.

    .EXAMPLE
    'ZW1wdHk=' | ConvertFrom-BMNativeApiByteValue

    Demonstrates that you can pipe values to `ConvertFrom-BMNativeApiByteValue`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [String] $InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process
    {
        $bytes = [Convert]::FromBase64String($InputObject)
        [Text.Encoding]::UTF8.GetString($bytes) | Write-Output
    }

    end
    {
    }
}
