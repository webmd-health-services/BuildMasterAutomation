
function Get-BMVariable
{
    <#
    .SYNOPSIS
    Gets BuildMaster variables.

    .DESCRIPTION
    The `Get-BMVariable` function gets BuildMaster variables. By default, it gets all global variables. It can also get
    all variables for a specific environment, server, server role, application group, and application variables.

    To get a specific variable, pass the variable's id, name, or object `Variable` parameter. If the variable doesn't
    exist, the function writes an error. To search for a variable, pass a wildcard string to the `Variable` parameter.

    To get an environment's variables, pass the environment's id, name, or object to the `Environment` parameter.

    To get a server role's variables, pass the server role's name to the `ServerRole` parameter.

    To get a server's variables, pass the server's name to the `Server` parameter.

    To get an application group's variables, pass the application group's name to the `ApplicationGroup` parameter.

    To get an application's variables, pass the application's name to the `Application` parameter.

    This function uses BuildMaster's [Variables Management](https://docs.inedo.com/docs/buildmaster-reference-api-variables)
    API. Due to a bug in BuildMaster, when getting application or application group variables, it uses BuildMaster's
    native API.

    .EXAMPLE
    Get-BMVariable

    Demonstrates how to get all global variables.

    .EXAMPLE
    Get-BMVariable -Session $session -Variable 'Var'

    Demonstrates how to get a specific global variable.

    .EXAMPLE
    Get-BMVariable -Session $session -Environment 'Dev'

    Demonstrates how to all an environment's variables.

    .EXAMPLE
    Get-BMVariable -Session $session -Variable 'Var' -Environment 'Dev'

    Demonstrates how to get a specific variable in an environment.

    .EXAMPLE
    Get-BMVariable -Session $session -ServerRole 'WebApp'

    Demonstrates how to get all variables in a specific server role.

    .EXAMPLE
    Get-BMVariable -Session $session -Variable 'Var' -ServerRole 'WebApp'

    Demonstrates how to get a specific variable in a server role.

    .EXAMPLE
    Get-BMVariable -Session $session -Server 'example.com'

    Demonstrates how to get all variables for a specific server.

    .EXAMPLE
    Get-BMVariable -Session $session -Variable 'Var' -Server 'example.com'

    Demonstrates how to get a specific variable in a server.

    .EXAMPLE
    Get-BMVariable -Session $session -ApplicationGroup 'WebApps'

    Demonstrates how to get all variables from a specific application group.

    .EXAMPLE
    Get-BMVariable -Session $session -Variable 'Var' -ApplicationGroup 'WebApps'

    Demonstrates how to get a specific variable from an application group.

    .EXAMPLE
    Get-BMVariable -Session $session -Application 'www'

    Demonstrates how to get all variables from a specific application.

    .EXAMPLE
    Get-BMVariable -Session $session -Variable 'Var' -Application 'www'

    Demonstrates how to get a specific variable from an application.
    #>
    [CmdletBinding(DefaultParameterSetName='global')]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [object] $Session,

        # The variable to get. Pass a variable id, name, or object. If you pass a string, wildcards are supported, and
        # only variables whose name equal or match the string will be returned.
        [Parameter(ValueFromPipeline)]
        [Object] $Variable,

        # The application of the variable. Pass an application id, name, or object.
        [Parameter(Mandatory, ParameterSetName='application')]
        [Alias('ApplicationName')]
        [Object] $Application,

        # The application group of the variable. Pass an application group id, name, or object.
        [Parameter(Mandatory, ParameterSetName='application-group')]
        [Alias('ApplicationGroupName')]
        [Object] $ApplicationGroup,

        # The environment of the variable. Pass an environment id, name, or object.
        [Parameter(Mandatory, ParameterSetName='environment')]
        [Alias('EnvironmentName')]
        [Object] $Environment,

        # The server of the variable. Pass an server id, name, or object.
        [Parameter(Mandatory, ParameterSetName='server')]
        [Alias('ServerName')]
        [Object] $Server,

        # The server role of the variable. Pass an server role id, name, or object.
        [Parameter(Mandatory, ParameterSetName='role')]
        [Alias('ServerRoleName')]
        [Object] $ServerRole,

        # Return the variable's value, not an object representing the variable.
        [switch] $ValueOnly
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false  # This function does not modify any data, but uses POST requests.

        $variableArg = @{}
        if ($Variable)
        {
            $variableArg['Variable'] = $Variable
        }

        Invoke-BMVariableEndpoint -Session $session `
                                  @variableArg `
                                  -EntityTypeName $PSCmdlet.ParameterSetName `
                                  -BoundParameter $PSBoundParameters |
            ForEach-Object {
                if ($ValueOnly)
                {
                    return $_.Value
                }
                return $_
            } |
            Write-Output

    }
}