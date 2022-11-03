
function New-BMPackage
{
    <#
    .SYNOPSIS
    Obsolete. Use "New-BMBuild" instead.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object] $Session,

        [Parameter(Mandatory, ParameterSetName='ByReleaseID')]
        [Object] $Release,

        [Parameter(Mandatory, ParameterSetName='ByReleaseNumber')]
        [String] $ReleaseNumber,

        [Parameter(Mandatory, ParameterSetName='ByReleaseNumber')]
        [Object] $Application,

        [string] $PackageNumber,

        [hashtable] $Variable
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $msg = 'The BuildMasterAutomation module''s "New-BMPackage" function is obsolete and will be removed in a future ' +
           'version of BuildMasterAutomation. Use the "Get-BMBuild" function instead.'
    Write-WarningOnce $msg

    $newArgs = @{}
    foreach ($paramName in @('Release', 'ReleaseNumber', 'Application', 'PackageNumber', 'Variable'))
    {
        if (-not $PSBoundParameters.ContainsKey($paramName))
        {
            continue
        }

        $newParamName = $paramName
        if ($paramName -eq 'PackageNumber')
        {
            $newParamName = 'BuildNumber'
        }

        $newArgs[$newParamName] = $PSBoundParameters[$paramName]
    }

    New-BMBuild -Session $Session @newArgs
}