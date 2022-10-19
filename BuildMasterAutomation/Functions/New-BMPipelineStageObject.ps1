
function New-BMPipelineStageObject
{
    <#
    .SYNOPSIS
    Creates a pipeline stage object that can be passed to `Set-BMPipeline`.

    .DESCRIPTION
    The `New-BMPipelineStageObject` creates an object that represents a stage of a pipeline. The object returned can be
    passed to the `Set-BMPipeline` function's `Stage` parameter. Pass the name of the stage to the `Name` parameter, the
    description to the `Description` parameter, and the stage targets to the `Target` parameter. Target objects can be
    created with the `New-BMPipelineStageTargetObject` function.

    .EXAMPLE
    New-BMPipelineStageObject -Name 'Example'

    Demonstrates how to create a stage object with just a name.
    #>
    [CmdletBinding()]
    param(
        # The stage's name.
        [Parameter(Mandatory)]
        [String] $Name,

        # The stage's description.
        [String] $Description,

        # A list of target objects for the stage. Target objects can be created with the
        # `New-BMPipelineStageTargetObject` function.
        [Parameter(ValueFromPipeline)]
        [Object[]] $Target
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $stage = [pscustomobject]@{
            Name = $Name;
            Description = $Description;
            Targets = $null;
        }

        $targets = [Collections.ArrayList]::New()
    }

    process
    {
        foreach( $item in $Target )
        {
            [void]$targets.Add($item)
        }
    }

    end
    {
        $stage.Targets = $targets.ToArray()
        return $stage
    }
}