
function Add-PSTypeName
{
    <#
    .SYNOPSIS
    Adds a BuildMaster type name to an object.

    .DESCRIPTION
    The `Add-PSTypeName` function adds BuildMaster type names to an object. These types don't actually exist. The type
    names are used by PowerShell to decide what formats to use when displaying an object.

    If the `Server` switch is set, it adds a `Inedo.BuildMaster.Server` type name.

    If the `RaftItem` switch is set, it adds a `Inedo.BuildMaster.RaftItem` type name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $InputObject,

        [Parameter(Mandatory, ParameterSetName='Server')]
        [switch] $Server,

        [Parameter(Mandatory, ParameterSetName='RaftItem')]
        [switch] $RaftItem
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $typeName = 'Inedo.BuildMaster.{0}' -f $PSCmdlet.ParameterSetName
        $InputObject.pstypenames.Add( $typeName )
        $InputObject | Write-Output
    }
}