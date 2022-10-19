
function Test-BMID
{
    <#
    .SYNOPSIS
    Tests if an object is a BuildMaster ID.

    .DESCRIPTION
    The `Test-BMID` function tests if an object is actually an ID. An ID is any signed or unsigned integer type,
    including bytes.

    .EXAMPLE
    1 | Test-BMID

    Returns `$true`.

    .EXAMPLE
    '1' | Test-BMID

    Returns `$false`.

    .EXAMPLE
    $null | Test-BMID

    Returns `$false`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [AllowNull()]
        [AllowEmptyString()]
        [Object] $ID
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($null -eq $ID)
        {
            return $false
        }

        $intTypes = @(
            [TypeCode]::Byte,
            [TypeCode]::Int16,
            [TypeCode]::Int32,
            [TypeCode]::Int64,
            [TypeCode]::SByte,
            [TypeCode]::UInt16,
            [TypeCode]::UInt32,
            [TypeCode]::UInt64
        )

        return ([Type]::GetTypeCode($ID.GetType()) -in $intTypes)
    }
}