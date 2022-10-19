
function Set-BMPipeline
{
    <#
    .SYNOPSIS
    Creates a new pipeline in BuildMaster.

    .DESCRIPTION
    The `Set-BMPipeline` function creates or updates a pipeline in BuildMaster. Pass the name of the pipeline to the
    `Name` parameter. Pass the raft id or a raft object where the pipeline should be saved to the `Raft` parameter. A
    global pipeline will be created with no stages.

    To assign the pipeline to an application, pass the application's id, name or an application object to the
    `Application` parameter.

    To set the stages of the pipeline, use the `New-BMPipelineStageObject` and `New-BMPipelineStageTargetObject`
    functions to create the stages, then pass them to the `Stage` parameter. If the pipeline exists, you can use
    `Get-BMPipeline` to get the pipeline, modify its stage objects, then pass them to the `Stage` parameter.

    To set the post-deployment options of the pipeline, use `New-BMPipelinePostDeploymentOptionsObject` to create a
    post-deployment options object and pass that object to the `PostDeploymentOption` parameter.

    To set the color of the pipeline, pass the color in CSS RGB color format (e.g. `#aabbcc`) to the `Color` parameter.

    If you want stage order to be enforced by the pipeline, use the `EnforceStageSequence` switch.

    Any parameters *not* provided are not sent to BuildMaster in the create/update request. Those values won't be
    updated by BuildMaster. Any parameter you pass will cause the respective pipeline property to get updated to that
    value.

    This function uses [BuildMaster's native API](http://inedo.com/support/documentation/buildmaster/reference/api/native).

    .EXAMPLE
    Set-BMPipeline -Session $session -Name 'Powershell Module'

    Demonstrates how to create or update a global pipeline. In this example a pipeline named `PowerShell Module` will be
    created/updated that has no stages and uses BuildMaster's default values.

    .EXAMPLE
    Set-BMPipeline -Session $session -Name 'PowerShell Module' -Application $app

    Demonstrates how to create or update a pipeline for a specific application. In this example, the pipeline will be
    called `PowerShell Module` and it will be assigned to the `$app` application.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the pipeline.
        [Parameter(Mandatory)]
        [String] $Name,

        # The raft where the pipeline should be saved. Use `Get-BMRaft` to see a list of rafts. By default, uses
        # BuildMaster's default raft. Can be the ID of a raft or a raft object.
        [Object] $Raft,

        # The application to assign the pipeline to. Pass an application's id, name or an application object.
        [Object] $Application,

        # The background color BuildMaster should use when displaying the pipeline's name in the UI. Should be a CSS
        # hexadecimal color, e.g. `#ffffff`
        [String] $Color,

        # Stage configuration for the pipeline. Should be a list of objects returned by `New-BMPipelineStageObject` or
        # returned from `Get-BMPipeline`.
        [Object[]] $Stage,

        # If set, stage sequences will be enforced, i.e. builds can't be deployed to any stage. The default value in the
        # BuildMaster UI for this property is `true`.
        [switch] $EnforceStageSequence,

        # The post deploy options to use when creating the pipeline. Use the `New-BMPipelinePostDeploymentOptionsObject`
        # function to create a post-deployment option object.
        [Object] $PostDeploymentOption,

        # If set, a pipeline object will be returned.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $pipeline = [pscustomobject]@{
        Name = $Name;
        Color = $Color;
        EnforceStageSequence = $EnforceStageSequence.IsPresent;
        Stages = $Stage;
    }

    if ($PostDeploymentOption)
    {
        $pipeline | Add-Member -Name 'PostDeploymentOptions' -MemberType NoteProperty -Value $PostDeploymentOption
    }

    Set-BMRaftItem -Session $Session `
                   -Raft $script:defaultRaftId `
                   -TypeCode ([BMRaftItemTypeCode]::Pipeline) `
                   -Name $Name `
                   -Application $Application `
                   -Content ($pipeline | ConvertTo-Json -Depth 100) `
                   -PassThru:$PassThru |
        Add-BMPipelineMember -PassThru
}
