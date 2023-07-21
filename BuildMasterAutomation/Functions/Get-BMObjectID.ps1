
function Get-BMObjectID
{
    <#
    .SYNOPSIS
    Gets the ID from a BuildMaster object.

    .DESCRIPTION
    The `Get-BMObjectID` gets the value of the ID from a BuildMaster object. Pipe the object to the function (or pass
    it to the `InputObject` property). Pass the object type name to the `ObjectTypeName` property.  The function
    inspects the object passed in and:

    * if the object is $null, returns $null.
    * if the object is a numeric value, returns it.
    * returns the value of the object's `id` property, if it exists.
    * returns the value of the object's `$(ObjectTypeName)_Id` (e.g. Raft_Id, Application_Id) property, if it exists.
    * returns the value of the object's `$(ObjectTypeName)Id` property, if it exists.
    * if it can't find an id, writes an error and returns nothing.

    If you know the exact name of the property you want returned as an id, pass its name to the `PropertyName`
    parameter. In this case, the function inspects the object passed in and:

    * if the object is $null, returns $null.
    * if the object is a numeric value, returns it.
    * returns the value of the object's `$PropertyName` property, if it exists.

    .EXAMPLE
    1 | Get-BMObjectID -ObjectNameType DoesNotMatter

    Demonstrates that `Get-BMObjectID` will always return any integer value it is passed.

    .EXAMPLE
    $raft | Get-BMObjectID -ObjectTypeName 'Raft'

    Demonstrates how to get the id from an object returned by any BuildMaster API. In this case, the object is a raft,
    and the function will return the value of the first of these properties to exist: `id`, `Raft_Id`, `RaftId`.

    .EXAMPLE
    $raftItem | Get-BMObjectID -PropertyName 'ApplicationGroup_Id'

    Demonstrates how to get the value of an id using a specific property name. In this example, if `$raftItem` is an
    integer, it will be returned, otherwise, the value of the `$raftItem.ApplicationGroup_Id` is returned.
    #>
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $InputObject,

        [Parameter(Mandatory, ParameterSetName='ByPropertyName')]
        [String] $PropertyName,

        [Parameter(Mandatory, ParameterSetName='ByObjectTypeName')]
        [String] $ObjectTypeName
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($null -eq $InputObject)
        {
            return $null
        }

        if ($InputObject | Test-BMID)
        {
            return [int]$InputObject
        }

        if (-not $PropertyName)
        {
            $PropertyName = 'Id'
        }

        if ($InputObject | Get-Member -Name $PropertyName)
        {
            return [int]($InputObject.$PropertyName)
        }

        if ($PSBoundParameters.ContainsKey('PropertyName'))
        {
            $msg = "Object does not have a ""${PropertyName}"" property."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        if (-not $ObjectTypeName)
        {
            $ObjectTypeName = '*'
        }

        $idProperty = $InputObject | Get-Member -Name "$($ObjectTypeName)_Id"
        if (-not $idProperty)
        {
            $idProperty = $InputObject | Get-Member -Name "$($ObjectTypeName)Id"
            if (-not $idProperty)
            {
                $msg = "Object ""$($InputObject)"" is not an id and does not have ""Id"", ""$($ObjectTypeName)_Id"", " +
                       "or ""$($ObjectTypeName)Id"" properties."
                Write-Error $msg -ErrorAction $ErrorActionPreference
                return
            }
        }

        $nameCount = ($idProperty | Measure-Object).Count
        if ($nameCount -gt 1)
        {
            $msg = "Object has multiple id properties: ""$($idProperty -join '", "')"". Use the " +
                   '"PropertyName" parameter to set the name of the property to get.'
            Write-Error $msg -ErrorAction $ErrorActionPreference
            return
        }

        return [int]($InputObject.($idProperty.Name))
    }
}