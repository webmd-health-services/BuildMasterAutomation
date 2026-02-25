
function ConvertTo-BMNativeApiByteValue
{
    <#
    .SYNOPSIS
    Converts a string into a value that can be passed to a `byte[]` parameter in the BuildMaster native API.

    .DESCRIPTION
    Some of the parameters of the BuildMaster native API are typed as `byte[]` object. This function converts strings
    into a value that can be passed as one of these parameters. Pipe the string you want to convert (or pass it to the
    `InputObject` parameter). The function will return a value that you can pass to the BuildMaster API.

    If you pipe multiple strings to `ConvertTo-BMNativeApiByteValue`, the strings will be concatenated together before
    conversion.

    .EXAMPLE
    ConvertTo-BMNativeApiByteValue 'hello example'

    Demonstrates how to convert a string into value that can be passed to a `byte[]`-typed parameter on the BuildMaster
    native API.

    .EXAMPLE
    'hello','example' | ConvertTo-BMNativeApiByteValue

    Demonstrates that you can pipe strings to `ConvertTo-BMNativeApiByteValue`. All the strings piped in will be
    concatenated together before conversion.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
       [AllowEmptyString()]
        [String] $InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $allStrings = [Text.StringBuilder]::New()
    }

    process
    {
        [void] $allStrings.Append($InputObject)
    }

    end
    {
        $stringBytes = [Text.Encoding]::UTF8.GetBytes($allStrings.ToString())
        [Convert]::ToBase64String($stringBytes) | Write-Output
    }
}