
function Add-BMPipelineMember
{
    <#
    .SYNOPSIS
    Adds `Pipeline_Name` and `Pipeline_Id` properties to an object.

    .DESCRIPTION
    In BuildMaster 6.2, pipeline objects are now rafts and now have `RaftItem_Name` and `RaftItem_Id` properties instead
    of `Pipeline_Name` and `Pipeline_Id` objects. This function adds `Pipeline_Name` and `Pipeline_Id` *alias*
    properties to an object that alias the `RaftItem_Name` and `RaftItem_Id` properties, respectively. You should only
    pipe raft items that represent pipelines to this function. It does *not* validate the incoming object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Pipeline,

        [switch] $PassThru
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if (-not $Pipeline)
        {
            return
        }

        $Pipeline |
            Add-Member -Name 'Pipeline_Name' -MemberType AliasProperty -Value 'RaftItem_Name' -PassThru |
            Add-Member -Name 'Pipeline_Id' -MemberType AliasProperty -Value 'RaftItem_Id' -PassThru:$PassThru
    }
}