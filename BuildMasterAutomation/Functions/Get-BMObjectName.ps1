
function Get-BMObjectName
{
    <#
    .SYNOPSIS
    Returns the name of an object that was returned by the BuildMaster API.

    .DESCRIPTION
    The BuildMasterAutomation module allows you to pass ids, names, or objects as the value to many parameters. Use the
    `Get-BMObjectName` function to get the name of one of these parameter values.

    If passed a string or an id, those will be returned as the name. Otherwise, the function looks for a `Name`
    property, a property matching wildcard `*_Name`, and then a property matching wildcard `*Name`, and returns the
    value of the first property found. If no properties are found, the function writes an error.

    If an object has multiple properties that could be its name, pass the name of the property to use to the
    `PropertyName` function.

    .EXAMPLE
    $app | Get-BMObjectName

    Demonstrates how to get the name of an application object. In this case, the value of the application's
    `Application_Name` property will be returned.
    #>
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $InputObject,

        [Parameter(Mandatory, ParameterSetName='ByPropertyName')]
        [String] $PropertyName,

        [Parameter(Mandatory, ParameterSetName='ByObjectTypeName')]
        [String] $ObjectTypeName,

        [switch] $Strict
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($null -eq $InputObject)
        {
            return $null
        }

        if ($InputObject | Test-BMName)
        {
            return $InputObject
        }

        if (-not $PropertyName)
        {
            $PropertyName = 'Name'
        }

        if ($InputObject | Get-Member -Name $PropertyName)
        {
            return $InputObject.$PropertyName
        }

        if ($PSBoundParameters.ContainsKey('PropertyName'))
        {
            if (-not $Strict -and ($InputObject | Test-BMID))
            {
                return $InputObject
            }

            $msg = "Object does not have a ""${PropertyName}"" property."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        if (-not $ObjectTypeName)
        {
            $ObjectTypeName = '*'
        }

        $nameProperty = $InputObject | Get-Member -Name "$($ObjectTypeName)_Name"
        if (-not $nameProperty)
        {
            $nameProperty = $InputObject | Get-Member -Name "$($ObjectTypeName)Name"
            if (-not $nameProperty)
            {
                if (-not $Strict -and ($InputObject | Test-BMID))
                {
                    return $InputObject
                }

                $msg = "Object ""$($InputObject)"" does not have ""Name"", ""$($ObjectTypeName)_Name"", or " +
                       """$($ObjectTypeName)Name"" properties."
                Write-Error $msg -ErrorAction $ErrorActionPreference
                return
            }
        }

        $nameCount = ($nameProperty | Measure-Object).Count
        if ($nameCount -gt 1)
        {
            $msg = "Object has multiple name properties: ""$($nameProperty -join '", "')"". Use the " +
                   '"PropertyName" parameter to set the name of the property to get.'
            Write-Error $msg -ErrorAction $ErrorActionPreference
            return
        }

        return $InputObject.($nameProperty.Name)
    }
}