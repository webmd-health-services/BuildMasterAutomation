
function Test-BMObject
{
    <#
    .SYNOPSIS
    Tests if an object is a BuildMaster object.

    .DESCRIPTION
    The `Test-BMObject` function tests if an object is actually a name.

    .EXAMPLE
    1 | Test-BMObject

    Returns `$false`.

    .EXAMPLE
    'YOLO' | Test-BMObject

    Returns `$false`.

    .EXAMPLE
    Get-BMApplication -Session $session -Name 'MyApp' | Test-BMObject

    Returns `$true`.

    .EXAMPLE
    $null | Test-BMObject

    Returns `$false`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [AllowNull()]
        [AllowEmptyString()]
        [Object] $Object
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($null -eq $Object)
        {
            return $false
        }

        return (-not ($Object | Test-BMID) -and -not ($Object | Test-BMName))
    }
}