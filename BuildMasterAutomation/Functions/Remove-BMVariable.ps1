
function Remove-BMVariable
{
    <#
    .SYNOPSIS
    Deletes BuildMaster variables.

    .DESCRIPTION
    The `Remove-BMVariable` function deletes BuildMaster variables. By default, it deletes global variables. It can also
    delete variables for a specific environment, server, server role, application group, application, release, and
    build.

    Pass the name of the variable to delete to the `Name` parameter. If no variable exists to delete, you'll get an
    error.

    To delete an environment's variables, pass the environment's name, ID or object to the `Environment` parameter.

    To delete a server role's variables, pass the server role's name, ID, or object to the `ServerRole` parameter.

    To delete a server's variables, pass the server's name, ID, or object to the `Server` parameter.

    To delete an application group's variables, pass the application group's name, ID, or object to the
    `ApplicationGroup` parameter.

    To delete an application's variables, pass the application's name, ID, or object to the `Application` parameter.

    To delete a release's variables, pass the release object to the `Release` parameter. Use the `Get-BMRelease`
    function to get a release object.

    To delete a build's variables, pass the build object to the `Build` parameter. Use the `Get-BMBuild` function to get
    a build object.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use
    `New-BMSession` to create a session object.

    This function uses BuildMaster's [Variables
    Management](https://docs.inedo.com/docs/buildmaster-reference-api-variables) API. Due to a bug in BuildMaster, when
    getting application or application group variables, it uses BuildMaster's native API.


    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var'

    Demonstrates how to delete a global variable.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -Environment 'Dev'

    Demonstrates how to delete a variable in an environment.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -ServerRole 'WebApp'

    Demonstrates how to delete a variable in a server role.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -Server 'example.com'

    Demonstrates how to delete a variable in a server.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -ApplicationGroup 'WebApps'

    Demonstrates how to delete a variable from an application group.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -Release (Get-BMRelease -Session $session -Release 'gitflow' -Application 'WebApp')

    Demonstrates how to delete a variable from a release.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -Build (Get-BMBuild -Session $session -Build 123)

    Demonstrates how to delete a variable from a build.

    .EXAMPLE
    Remove-BMVariable -Session $session -Name 'Var' -Application 'www'

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

        # The application of the variable to delete. Pass an application ID, name, or object.
        [Parameter(Mandatory, ParameterSetName='application')]
        [Object] $Application,

        # The application group of the variable to delete. Pass an application group ID, name, or object.
        [Parameter(Mandatory, ParameterSetName='application-group')]
        [Object] $ApplicationGroup,

        # The environment of the variable to delete. Pass an environment ID, name, or object.
        [Parameter(Mandatory, ParameterSetName='environment')]
        [Object] $Environment,

        # The server of the variable to delete. Pass a server ID, name, or object.
        [Parameter(Mandatory, ParameterSetName='server')]
        [Object] $Server,

        # The server role of the variable to delete. Pass a server role ID, name, or object.
        [Parameter(Mandatory, ParameterSetName='role')]
        [Object] $ServerRole,

        # Specific release of the variable to delete. Must be a Release object returned from the `Get-BMRelease` function.
        [Parameter(Mandatory, ParameterSetName='releases')]
        [Object] $Release,

        # Specific build of the variable to delete. Must be a Build object returned from the `Get-BMBuild` function.
        [Parameter(Mandatory, ParameterSetName='builds')]
        [Object] $Build
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
