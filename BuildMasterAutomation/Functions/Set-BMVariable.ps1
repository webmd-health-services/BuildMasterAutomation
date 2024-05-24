
function Set-BMVariable
{
    <#
    .SYNOPSIS
    Create or set a BuildMaster variable.

    .DESCRIPTION
    The `Set-BMVariable` function creates or sets the value of a BuildMaster variable. By default, it creates/sets
    global variables. It can also set variables for a specific environment, server, server role, application group,
    application, release, and build.

    Pass the variable's name to the `Name` parameter and pass the variable's value to the `Value` parameter.

    The function takes variable values as PowerShell data structures and converts them to OtterScript expressions before
    they're passed to BuildMaster. A PowerShell hashtable is converted to an OtterScript map, a PowerShell array is
    converted to an OtterScript vector, and any other types are passed as their default string representation.

    Use the `Raw` switch to pass the variable value as-is to BuildMaster, i.e. no type conversion.

    To set an environment's variable, pass the environment's name to the `EnvironmentName` parameter.

    To set a server role's variable, pass the server role's name to the `ServerRoleName` parameter.

    To set a server's variable, pass the server's name to the `ServerName` parameter.

    To set an application group's variable, pass the application group's name to the `ApplicationGroupName` parameter.

    To set an application's variable, pass the application's name to the `ApplicationName` parameter.

    To set a release's variable, pass the release object to the `Release` parameter. Use the `Get-BMRelease` function to
    get a release object.

    To set a build's variable, pass the build object to the `Build` parameter. Use the `Get-BMBuild` function to get a
    build object.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use
    `New-BMSession` to create a session object.

    This function uses BuildMaster's variables API.

    .EXAMPLE
    Set-BMVariable -Session $session -Name 'Var' -Value 'Value'

    Demonstrates how to create or set a global variable.

    .EXAMPLE
    Set-BMVariable -Session $session -Name 'Var' -Value 'Value' -EnvironmentName 'Dev'

    Demonstrates how to create or set a variable in an environment.

    .EXAMPLE
    Set-BMVariable -Session $session -Name 'Var' -Value 'Value' -ServerRoleName 'WebApp'

    Demonstrates how to create or set a variable for a server role.

    .EXAMPLE
    Set-BMVariable -Session $session -Name 'Var' -Value 'Value' -ServerName 'example.com'

    Demonstrates how to create or set a variable for a server.

    .EXAMPLE
    Set-BMVariable -Session $session -Name 'Var' -Value 'Value' -ApplicationGroupName 'WebApps'

    Demonstrates how to create or set a variable for an application group.

    .EXAMPLE
    Set-BMVariable -Session $session -Name 'Var' -Value 'Value' -ApplicationName 'www'

    Demonstrates how to create or set a variable for an application.

    .EXAMPLE
    Set-BMVariable -Session $session -Name 'Var' -Value 'Value' -Release (Get-BMRelease -Session $session -Release 'gitflow' -Application 'WebApp')

    Demonstrates how to set a variable for a release.

    .EXAMPLE
    Set-BMVariable -Session $session -Name 'Var' -Value 'Value' -Build (Get-BMBuild -Session $session -Build 123)

    Demonstrates how to set a variable for a build.

    .EXAMPLE
    Set-BMVariable -Session $session -Name 'var' -Value @('hi', 'there') -ApplicationName 'www'

    Demonstrates how to set the variable 'var' to an OtterScript vector.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='global')]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the variable to create.
        [Parameter(Mandatory)]
        [String] $Name,

        # The variable's value. If a PowerShell array or hashtable is passed in it will be converted to the equivalent
        # OtterScript expression.
        [Parameter(Mandatory)]
        [Object] $Value,

        # The name of the application where the variable should be created. The default is to create a global variable.
        [Parameter(Mandatory,ParameterSetName='application')]
        [Alias('ApplicationName')]
        [Object] $Application,

        # The name of the application group where the variable should be created. The default is to create a global variable.
        [Parameter(Mandatory,ParameterSetName='application-group')]
        [Alias('ApplicationGroupName')]
        [Object] $ApplicationGroup,

        # The name of the environment where the variable should be created. The default is to create a global variable.
        [Parameter(Mandatory,ParameterSetName='environment')]
        [Alias('EnvironmentName')]
        [Object] $Environment,

        # The name of the server where the variable should be created. The default is to create a global variable.
        [Parameter(Mandatory,ParameterSetName='server')]
        [Alias('ServerName')]
        [Object] $Server,

        # The name of the server role where the variable should be created. The default is to create a global variable.
        [Parameter(Mandatory,ParameterSetName='role')]
        [Alias('ServerRoleName')]
        [Object] $ServerRole,

        # Specific release where the variable will be created. Must be a Release object returned from the `Get-BMRelease` function.
        [Parameter(Mandatory, ParameterSetName='releases')]
        [Object] $Release,

        # Specific build where the variable will be created. Must be a Build object returned from the `Get-BMBuild` function.
        [Parameter(Mandatory, ParameterSetName='builds')]
        [Object] $Build,

        # Pass the value as-is to BuildMaster, do not attempt to convert to OtterScript expression.
        [switch] $Raw
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if (-not $Raw)
    {
        $Value = ConvertTo-BMOtterScriptExpression -Value $Value

        if ($Value -eq $null)
        {
            return
        }
    }

    Invoke-BMVariableEndpoint -Session $Session `
                              -Variable $Name `
                              -Value $Value `
                              -EntityTypeName $PSCmdlet.ParameterSetName `
                              -BoundParameter $PSBoundParameters
}