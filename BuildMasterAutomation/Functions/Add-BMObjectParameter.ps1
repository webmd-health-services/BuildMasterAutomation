
function Add-BMObjectParameter
{
    <#
    .SYNOPSIS
    Adds id or name values to a parameter hashtable (i.e. a hashtable used as the body of a request to a BuildMaster API
    endpoint).

    .DESCRIPTION
    Many of BuildMaster's APIs take an ID or a name. For example, many of the Release and Build Deployment methods
    accept either an `applicationId` parameter *or* an `applicationName` parameter. This function exists to allow
    BuildMasterAutomation functions to accept an object, an object's id or an object's name as a parameter. Pipe the
    hashtable that will be used as the body of a request to the BuildMaster APIs to `Add-BMObjectParameter`. Pass the
    name of the object type to the `Name` parameter and the object/id/name/value to the `Value` parameter.

    If the value passed is `$null`, nothing happens. If the value passed is a byte or an integer, the function adds a
    `$($Name)Id` parameter to the hashtable. If the value passed is a string, the function adds a `$($Name)Name`
    parameter. Otherwise, `Add-BMObjectParameter` the first property on the property named `id`, `$($Name)Id`, `name`,
    or `$($Name)Name` is added as `$($Name)Id` or `$($Name)Name` respectively.

    If the hashtable will be used as the body to a native API endpoint, use the `-ForNativeApi` switch. The native API
    uses `$($Name)_Id` and `$($Name)_Name` patterns for its id and name parameters.

    If you want to return the original hasthable so you can add more than one parameter to the hashtable, use the
    `-PassThru` switch.

    .EXAMPLE
    $parameters | Add-BMObjectParameter -Name 'release' -Value $release

    Demonstrates how to add the id property from an object to a hashtable used as the body to a BuildMaster API
    endpoint.  In this case, `$release` is a release object returned by the BuildMaster APi, so has a `releaseId`
    property. `Add-BMObjectParameter` will add a `releaseId` key to the hashtable with a value of `$release.releaseId`.

    .EXAMPLE
    $parameters | Add-BMObjectParameter -Name 'release' -Value $releaseId

    Demonstrates how to add an id to a hashtable used as the body to a BuildMaster API. In this case, `$releaseId` is
    the id of a release. `Add-BMObjectParameter` will add a `releaseId` key to the hashtable with a value of
    `$releaseId`.

    .EXAMPLE
    $parameters | Add-BMObjectParameter -Name 'release' -Value $releaseName

    Demonstrates how to add a name to a hashtable used as the body to a BuildMaster API. In this case, `$releaseName` is
    the name of a release. `Add-BMObjectParameter` will add a `releaseName` key to the hashtable with a value of
    `$releaseName`.

    .EXAMPLE
    $parameters | Add-BMObjectParameter -Name 'pipeline' -Value $pipeline -AsName

    Demonstrates how to force `Add-BMObjectParameter` to ignore any id properties and only use name properties, if they
    exist, by using the `AsName` switch.

    .EXAMPLE
    $parameters | Add-BMObjectParameter -Name 'application' -Value $app -ForNativeApi

    Demonstrates how to add an id parameter to a parameter hashtable used as the body of a request to the BuildMaster
    *Native* API. In this case, `$app` is an application object returned by the BuildMaster API. `Add-BMObjectParameter`
    will add an `application_Id` key to the hasthable with a value of `$app.application_Id`.

    .EXAMPLE
    $parameter | Add-BMObjectParameter -Name 'application' -Value $app -PassThru | Add-BMObjectParameter -Name 'pipeline' -Value $pipeline

    Demonstrates how you can use the `PassThru` switch to add multiple parameters to a parameters hashtable using a
    pipeline.
    #>
    [CmdletBinding()]
    param(
        # The hashtable to add the parameter to.
        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable] $Parameter,

        # The name of the parameter, *without* the `Id` or `Name` suffix. The suffix is added automatically based on the
        # type of the parameter value.
        [Parameter(Mandatory)]
        [String] $Name,

        # The object, id, or name.
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [Object] $Value,

        # If true, will return the hashtable.
        [switch] $PassThru,

        # The parameters are being used in the native API, which has a different naming convention. If true, parameter
        # names will use an underscore in the parameter name added to the hashtable, e.g. `_Id` or `_Name`.
        [switch] $ForNativeApi,

        # If set, id properties on the incoming object will be ignored.
        [switch] $AsName
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($null -eq $Value)
        {
            if ($PassThru)
            {
                return $Parameter
            }

            return
        }


        $isId = $false
        $idValue = $Value
        $isName = $false
        $nameValue = $Value

        $nativeApiIdParamName = '{0}_Id' -f $Name
        if ($Value | Test-BMID)
        {
            $isId = $true
            $idValue = $Value
        }
        elseif ($Value | Get-Member -Name 'id')
        {
            $isId = $true
            $idValue = $Value.id
        }
        elseif ($Value | Get-Member -Name $nativeApiIdParamName)
        {
            $isId = $true
            $idValue = $Value.$nativeApiIdParamName
        }

        $nativeApiNameParamName = '{0}_Name' -f $Name
        if ($Value | Test-BMName)
        {
            $isName = $true
            $nameValue = $Value
        }
        elseif ($Value | Get-Member -Name 'name')
        {
            $isName = $true
            $nameValue = $Value.name
        }
        elseif ($Value | Get-Member -Name $nativeApiNameParamName)
        {
            $isName = $true
            $nameValue = $value.$nativeApiNameParamName
        }

        $idParamName = '{0}Id' -f $Name
        $nameParamName = '{0}Name' -f $Name
        if ( $ForNativeApi )
        {
            $idParamName = $nativeApiIdParamName
            $nameParamName = $nativeApiNameParamName
        }

        if ($isId -and -not $AsName)
        {
            $paramName = $idParamName
            $paramValue = $idValue
        }
        elseif ($isName)
        {
            $paramName = $nameParamName
            $paramValue = $nameValue
        }
        else
        {
            $msg = "Unable to find id or name properties on ""$($Value)""."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            if ($PassThru)
            {
                reeturn $Parameter
            }
            return
        }

        $Parameter | Add-BMParameter -Name $paramName -Value $paramValue -PassThru:$PassThru
    }
}

