
function Get-BMPackage
{
    <#
    .SYNOPSIS
    Obsolete. Use `Get-BMBuild` instead.
    #>
    [CmdletBinding(DefaultParameterSetName='AllBuilds')]
    param(
        [Parameter(Mandatory)]
        [Object] $Session,

        [Parameter(Mandatory, ParameterSetName='SpecificPackage')]
        [Object] $Package,

        [Parameter(Mandatory, ParameterSetName='ReleasePackages')]
        [Object] $Release
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $msg = 'The BuildMasterAutomation module''s "Get-BMPackage" function is obsolete and will be removed in a future ' +
           'version of BuildMasterAutomation. Use the "Get-BMBuild" function instead.'
    Write-WarningOnce $msg

    $getArgs = @{}
    if ($PSCmdlet.ParameterSetName -eq 'SpecificPackage')
    {
        $getArgs['Build'] = $Package
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'ReleasePackages')
    {
        $getArgs['Release'] = $Release
    }
    Get-BMBuild -Session $Session @getArgs
}
