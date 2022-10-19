
function Get-BMDeployment
{
    <#
    .SYNOPSIS
    Gets a deployment from BuildMaster.

    .DESCRIPTION
    The `Get-BMDeployment` function gets a deployment from BuildMaster. Pass the deployment id or deployment object to
    the `Deployment` parameter. That deployment will be returned.

    This function uses the
    [Release and Build Deployment API](https://docs.inedo.com/docs/buildmaster-reference-api-release-and-build).

    .EXAMPLE
    Get-BMDeployment -Session $session

    Demonstrates how to get all deployments from the instance of BuildMaster.

    .EXAMPLE
    Get-BMDeployment -Session $session -Deploytment $deployment

    Demonstrates how to get a specific deployment by passing a deployment object to the `Deployment` parameter. The
    `Get-BMDeployment` function looks for an `id` property on the object.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The deployment to get. You can pass a deployment id or object.
        [Parameter(Mandatory)]
        [Alias('ID')]
        [Object] $Deployment
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $parameter =
            @{ } |
            Add-BMObjectParameter -Name 'deployment' -Value $Deployment -PassThru
        Invoke-BMRestMethod -Session $Session -Name 'releases/builds/deployments' -Parameter $parameter -Method Post
    }
}
