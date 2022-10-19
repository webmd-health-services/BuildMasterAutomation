
function New-BMPipelinePostDeploymentOptionsObject
{
    <#
    .SYNOPSIS
    Creates an object to pass to `Set-BMPipeline` to set a pipeline's post-deployment options.

    .DESCRIPTION
    The `New-BMPipelinePostDeploymentOptionsObject` creates an object representing the post-deployment options for a
    pipeline. The object returned should be passed to the `Set-BMPipeline` function's `-PostDeploymentOption` parameter.

    If you don't pass any arguments, the post-deployment options object will have no properties. We don't know what the
    behavior of `Set-BMPipeline` will be in the case. We assume it will remove explicitly set values, reverting them to
    their defaults.

    .EXAMPLE
    New-BMPipelinePostDeploymentOptionsObject -CancelEarlierRelease $true -CreateNewRelease $true -DeployRelease $false

    Demonstrates how to create a post-deployment options object that sets the options to the opposite of BuildMaster's
    defaults.

    .EXAMPLE
    New-BMPipelinePostDeploymentOptionsObject -MarkDeployed $false

    Demonstrates how to turn off a single option.
    #>
    [CmdletBinding()]
    param(
        [bool] $CancelEarlierReleases,

        [bool] $CreateNewRelease,

        [bool] $MarkDeployed
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $options = @{ }

    if ($PSBoundParameters.ContainsKey('CancelEarlierReleases'))
    {
        $options['CancelReleases'] = $CancelEarlierReleases
    }

    if ($PSBoundParameters.ContainsKey('CreateNewRelease'))
    {
        $options['CreateRelease'] = $CreateNewRelease
    }

    if ($PSBoundParameters.ContainsKey('MarkDeployed'))
    {
        $options['DeployRelease'] = $MarkDeployed
    }

    return [pscustomobject]$options
}