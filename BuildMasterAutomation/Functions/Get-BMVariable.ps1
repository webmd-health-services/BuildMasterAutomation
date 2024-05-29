
function Get-BMVariable
{
    <#
    .SYNOPSIS
    Gets BuildMaster variables.

    .DESCRIPTION
    The `Get-BMVariable` function gets BuildMaster variables. By default, it gets all global variables. It can also get
    all variables for a specific environment, server, server role, application group, application, release, and build.

    To get a specific variable, pass the variable's id, name, or object `Variable` parameter. If the variable doesn't
    exist, the function writes an error. To search for a variable, pass a wildcard string to the `Variable` parameter.

    To get an environment's variables, pass the environment's id, name, or object to the `Environment` parameter.

    To get a server role's variables, pass the server role's name to the `ServerRole` parameter.

    To get a server's variables, pass the server's name to the `Server` parameter.

    To get an application group's variables, pass the application group's name to the `ApplicationGroup` parameter.

    To get an application's variables, pass the application's name to the `Application` parameter.

    To get a release's variables, pass the release object to the `Release` parameter. Use the `Get-BMRelease` function
    to get a release object.

    To get a build's variables, pass the build object to the `Build` parameter. Use the `Get-BMBuild` function to get a
    build object.

    This function returns the variable value as a PowerShell data structure. If the variable is an OtterScript vector,
    it converts it to a PowerShell array; if it is an OtterScript map, it converts it to a PowerShell hashtable. To
    return the variable value in its original OtterScript form as a PowerShell string, use the `Raw` switch.

    This function uses BuildMaster's [Variables Management](https://docs.inedo.com/docs/buildmaster-reference-api-variables)
    API. Due to a bug in BuildMaster, when getting application or application group variables, it uses BuildMaster's
    native API.

    .EXAMPLE
    Get-BMVariable

    Demonstrates how to get all global variables.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var'

    Demonstrates how to get a specific global variable.

    .EXAMPLE
    Get-BMVariable -Session $session -Environment 'Dev'

    Demonstrates how to all an environment's variables.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -Environment 'Dev'

    Demonstrates how to get a specific variable in an environment.

    .EXAMPLE
    Get-BMVariable -Session $session -ServerRole 'WebApp'

    Demonstrates how to get all variables in a specific server role.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -ServerRole 'WebApp'

    Demonstrates how to get a specific variable in a server role.

    .EXAMPLE
    Get-BMVariable -Session $session -Server 'example.com'

    Demonstrates how to get all variables for a specific server.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -Server 'example.com'

    Demonstrates how to get a specific variable in a server.

    .EXAMPLE
    Get-BMVariable -Session $session -ApplicationGroup 'WebApps'

    Demonstrates how to get all variables from a specific application group.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -ApplicationGroup 'WebApps'

    Demonstrates how to get a specific variable from an application group.

    .EXAMPLE
    Get-BMVariable -Session $session -Application 'www'

    Demonstrates how to get all variables from a specific application.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -Application 'www'

    Demonstrates how to get a specific variable from an application.

    .EXAMPLE
    Get-BMVariable -Session $session -Release (Get-BMRelease -Session $session -Release 'gitflow' -Application 'WebApp')

    Demonstrates how to get all the variables for the "gitflow" release on the "WebApp" application.

    .EXAMPLE
    Get-BMVariable -Session $session -Build (Get-BMBuild -Session $session -Build 123)

    Demonstrates how to get all the variables for build id 123.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -Application 'www' -Raw

    Demonstrates how to get a specific variable from an application as a string in its OtterScript expression form.
    #>
    [CmdletBinding(DefaultParameterSetName='global')]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [object] $Session,

        # The variable to get. Pass a variable id, name, or object. If you pass a string, wildcards are supported, and
        # only variables whose name equal or match the string will be returned.
        [Parameter(ValueFromPipeline)]
        [Object] $Name,

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

        # Specific release of the variable. Must be a Release object returned from the `Get-BMRelease` function.
        [Parameter(Mandatory, ParameterSetName='releases')]
        [Object] $Release,

        # Specific build of the variable. Must be a Build object returned from the `Get-BMBuild` function.
        [Parameter(Mandatory, ParameterSetName='builds')]
        [Object] $Build,

        # Return the variable's value, not an object representing the variable.
        [switch] $ValueOnly,

        # Return the variable's value as a string rather than converting to a PowerShell object.
        [switch] $Raw
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false  # This function does not modify any data, but uses POST requests.

        $variableArg = @{}
        if ($Name)
        {
            $variableArg['Variable'] = $Name
        }

        Invoke-BMVariableEndpoint -Session $session `
                                  @variableArg `
                                  -EntityTypeName $PSCmdlet.ParameterSetName `
                                  -BoundParameter $PSBoundParameters |
            ForEach-Object {
                if ($ValueOnly -and $Raw)
                {
                    return $_.Value
                }

                if ($ValueOnly)
                {
                    return ConvertFrom-BMOtterScriptExpression $_.Value
                }

                if ($Raw)
                {
                    return $_
                }

                $_.Value = ConvertFrom-BMOtterScriptExpression $_.Value
                return $_
            } |
            Write-Output

    }
}