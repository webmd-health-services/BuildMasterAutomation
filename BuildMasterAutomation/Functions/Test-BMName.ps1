
function Test-BMName
{
    <#
    .SYNOPSIS
    Tests if an object is a BuildMaster name.

    .DESCRIPTION
    The `Test-BMName` function tests if an object is actually a name.

    .EXAMPLE
    1 | Test-BMName

    Returns `$false`.

    .EXAMPLE
    'YOLO' | Test-BMName

    Returns `$true`.

    .EXAMPLE
    '$null | Test-BMName

    Returns `$false`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [AllowNull()]
        [AllowEmptyString()]
        [Object] $Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($null -eq $Name)
        {
            return $false
        }

        return ($Name -is [String])
    }
}