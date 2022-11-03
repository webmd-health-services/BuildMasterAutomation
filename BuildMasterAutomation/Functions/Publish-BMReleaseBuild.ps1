
function Publish-BMReleaseBuild
{
    <#
    .SYNOPSIS
    Deploys a release build in BuildMaster.

    .DESCRIPTION
    The `Publish-BMReleaseBuild` deploys a release build in BuildMaster. The build is deployed using the pipeline
    assigned to the release the build is part of. This function uses BuildMaster's
    [Release and Build Deployment API](http://inedo.com/support/documentation/buildmaster/reference/api/release-and-build).

    Pass the build to deploy to the `Build` parameter. This can be a build object or a build ID (as an integer).

    To deploy a build, it must be part of a release that has a pipeline. That pipeline must have at least one stage and
    that stage must have a plan. If none of these conditions are met, you'll get no object back with no errors written.

    .EXAMPLE
    Publish-BMReleaseBuild -Session $session -Build $build

    Demonstrates how to deploy a build by passing a build object to the `Build` parameter. This object must have an `id`
    or `pipeline_id` property.

    .EXAMPLE
    Publish-BMReleaseBuild -Session $session -Build 383

    Demonstrates how to deploy a build by passing its ID to the `Build` parameter.

    .EXAMPLE
    Publish-BMReleaseBuild -Session $session -Build $build -Stage $stage

    Demonstrates how to deploy a build to a specific stage of the release pipeline. By default, a build will deploy to
    the first stage of the assigned pipeline.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use the `New-BMSession` function to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The build to deploy. Can be a build id or object.
        [Parameter(Mandatory)]
        [Object] $Build,

        # The name of the pipeline stage where the build will be deployed.
        [String] $Stage,

        # Instructs BuildMaster to run the deploy even if the deploy to previous stages failed or the stage isn't the
        # first stage.
        [switch] $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameters = @{} | Add-BMObjectParameter -Name 'build' -Value $Build -PassThru

    if( $Stage )
    {
        $parameters['toStage'] = $Stage
    }

    if( $Force )
    {
        $parameters['force'] = 'true'
    }

    Invoke-BMRestMethod -Session $Session -Name 'releases/builds/deploy' -Parameter $parameters -Method Post
}
