
function Add-BMParameter
{
    <#
    .SYNOPSIS
    Adds values to a parameter hashtable (i.e. a hashtable used as the body of a request to a BuildMaster API endpoint).

    .DESCRIPTION
    The `Add-BMParameter` function adds values to a parameter hashtable. Pipe the hashtable to the function (or pass it
    to the `Parameter` parameter). Pass the parameter name to the `Name` parameter and the value to the `Value`
    parameter. If the value is not null, it will be added to the hashtable.

    This function lets you simplify adding optional parameters to a parameter hashtable. Instead of:

         if ($null -ne $Value)
         {
            $parameters[$Name] = $Value
         }

    this function lets you write:

        $parameters | Add-BMParameter -Name $Name -Value $Value

    It also lets you chain multiple parameters together by using the `-PassThru` switch:

        $parameters |
            Add-BMParameter -Name $Name1 -Value $Value1 -PassThru |
            Add-BMParameter -Name $Name2 -Value $Value2 -PassThru |
            Add-BMParameter -Name $Name3 -Value $Value3

    .EXAMPLE
    $parameters | Add-BMParameter -Name $Name -Value $Value

    Demonstrates how to add an optional parameter to the parameter hashtable `$parameters`. In this case, if `$Value`
    is not null, `Add-BMParameter` adds `$Value` into `$parameters` using key `$Name`, e.g.
    `$parameters[$Name] = $Value`.

    .EXAMPLE
    $parameters | Add-BMParameter -Name $Name -Value $Value -PassThru | Add-BMParameter -Name $Name2 -Value $Value2

    Demonstrates how you can add multiple parameters to a parameter hashtable by using the `-PassThru` switch, which
    returns the parameter hashtable, which be piped to `Add-BMParameter`.
    #>
    [CmdletBinding()]
    param(
        # The hashtable to add the parameter to.
        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable] $Parameter,

        # The name of the parameter.
        [Parameter(Mandatory)]
        [String] $Name,

        # The value of the parameter. If the value is not null, it is added to the `$Parameter` hashtable using the
        # name argument as the key.
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [Object] $Value,

        # If set, returns the hashtable piped (or passed to parameter `$Parameter). This lets you create a pipeline of
        # calls to `Add-BMParameter`.
        [switch] $PassThru
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($null -ne $Value)
        {
            if ($Value -is [hashtable])
            {
                $Parameter[$Name] = $Value[$Name]
            }
            elseif ($Value -is [Enum])
            {
                $enumType = [Enum]::GetUnderlyingType($Value.GetType())
                $Parameter[$Name] = [Convert]::ChangeType($Value, $enumType)
            }
            else
            {
                $Parameter[$Name] = $Value
            }
        }

        if ($PassThru)
        {
            return $Parameter
        }
    }


}

