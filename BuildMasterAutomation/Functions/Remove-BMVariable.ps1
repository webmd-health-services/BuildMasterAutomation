
function Remove-BMVariable
{
    <#
    .SYNOPSIS
    Deletes BuildMaster variables.

    .DESCRIPTION
    The `Remove-BMVariable` function deletes BuildMaster variables. By default, it deletes global variables. It can also delete variables for a specific environment, server, server role, application group, and application variables.

    Pass the name of the variable to delete to the `Name` parameter. If no variable exists to delete, you'll get an error.

    To delete an environment's variables, pass the environment's name to the `EnvironmentName` parameter.

    To delete a server role's variables, pass the server role's name to the `ServerRoleName` parameter.

    To delete a server's variables, pass the server's name to the `ServerName` parameter.

    To delete an application group's variables, pass the application group's name to the `ApplicationGroupName` parameter.

    To delete an application's variables, pass the application's name to the `ApplicationName` parameter.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use `New-BMSession` to create a session object.

    This function uses BuildMaster's variables API. When deleting application and application group variables, it uses BuildMaster's native API.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var'

    Demonstrates how to delete a global variable.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -EnvironmentName 'Dev'

    Demonstrates how to delete a variable in an environment.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -ServerRoleName 'WebApp'

    Demonstrates how to delete a variable in a server role.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -ServerName 'example.com'

    Demonstrates how to delete a variable in a server.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -ApplicationGroupName 'WebApps'

    Demonstrates how to delete a variable from an application group.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -ApplicationName 'www'

    Demonstrates how to delete a variable from an application.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "")]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='global')]
    param(
        # The session to BuildMaster. Use `New-PSSession` to create a new session.
        [Parameter(Mandatory)]
        [Object]$Session,

        # The variable to delete. Pass a variable name or variable object.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Variable,

        # The application of the variable to delete. Pass an application id, name, or object.
        [Parameter(Mandatory, ParameterSetName='application')]
        [Object] $Application,

        # The application group of the variable to delete. Pass an application group id, name, or object.
        [Parameter(Mandatory, ParameterSetName='application-group')]
        [Object] $ApplicationGroup,

        # The environment of the variable to delete. Pass an environment id, name, or object.
        [Parameter(Mandatory, ParameterSetName='environment')]
        [Object] $Environment,

        # The server of the variable to delete. Pass a server id, name, or object.
        [Parameter(Mandatory, ParameterSetName='server')]
        [Object] $Server,

        # The server role of the variable to delete. Pass a server role id, name, or object.
        [Parameter(Mandatory, ParameterSetName='role')]
        [Object] $ServerRole
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Invoke-BMVariableEndpoint -Session $session `
                                  -Variable $Variable `
                                  -EntityTypeName $PSCmdlet.ParameterSetName `
                                  -BoundParameter $PSBoundParameters `
                                  -ForDelete
    }

}