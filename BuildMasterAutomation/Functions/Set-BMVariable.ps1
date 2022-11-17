
function Set-BMVariable
{
    <#
    .SYNOPSIS
    Create or set a BuildMaster variable.

    .DESCRIPTION
    The `Set-BMVariable` function creates or sets the value of a BuildMaster variable. By default, it creates/sets global variables. It can also set environment, server, server role, application group, and application variables.

    Pass the variable's name to the `Name` parameter. Pass the variable's value to the `Value` parameter. The value is passed as-is to BuildMaster.

    To set an environment's variable, pass the environment's name to the `EnvironmentName` parameter.

    To set a server role's variable, pass the server role's name to the `ServerRoleName` parameter.

    To set a server's variable, pass the server's name to the `ServerName` parameter.

    To set an application group's variable, pass the application group's name to the `ApplicationGroupName` parameter.

    To set an application's variable, pass the application's name to the `ApplicationName` parameter.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use `New-BMSession` to create a session object.

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

        # The variable's value. Passed to BuildMaster as-is.
        [Parameter(Mandatory)]
        [String] $Value,

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
        [Object] $ServerRole
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Invoke-BMVariableEndpoint -Session $Session `
                              -Variable $Name `
                              -Value $Value `
                              -EntityTypeName $PSCmdlet.ParameterSetName `
                              -BoundParameter $PSBoundParameters
}