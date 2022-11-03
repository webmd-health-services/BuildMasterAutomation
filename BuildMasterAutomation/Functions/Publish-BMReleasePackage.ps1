
function Publish-BMReleasePackage
{
    <#
    .SYNOPSIS
    Obsolete. Use "Publish-BMReleaseBuild" instead.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object] $Session,

        [Parameter(Mandatory)]
        [Object] $Package,

        [String] $Stage,

        [switch] $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $msg = 'The BuildMasterAutomation module''s "Publish-BMReleasePackage" function is obsolete and will be removed ' +
           'in a future version of BuildMasterAutomation. Use the "Get-BMBuild" function instead.'
    Write-WarningOnce $msg

    $publishArgs = @{}
    foreach ($paramName in @('Stage', 'Force'))
    {
        if (-not $PSBoundParameters.ContainsKey($paramName))
        {
            continue
        }

        $publishArgs[$newParamName] = $PSBoundParameters[$paramName]
    }

    Publish-BMReleaseBuild -Session $Session -Build $Package @publishArgs
}
