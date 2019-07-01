
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

    This function uses BuildMaster's variables API.

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
    [CmdletBinding(DefaultParameterSetName='global')]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        # The name of the variable to delete.
        [string]$Name,

        [Parameter(Mandatory,ParameterSetName='application')]
        # The name of the application where the variable should be deleted. The default is to delete global variables.
        [string]$ApplicationName,

        [Parameter(Mandatory,ParameterSetName='application-group')]
        # The name of the application group where the variable should be deleted. The default is to delete global variables.
        [string]$ApplicationGroupName,

        [Parameter(Mandatory,ParameterSetName='environment')]
        # The name of the environment where the variable should be deleted. The default is to delete global variables.
        [string]$EnvironmentName,

        [Parameter(Mandatory,ParameterSetName='server')]
        # The name of the server where the variable should be deleted. The default is to delete global variables.
        [string]$ServerName,

        [Parameter(Mandatory,ParameterSetName='role')]
        # The name of the server role where the variable should be deleted. The default is to delete global variables.
        [string]$ServerRoleName
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $entityParamNames = @{
                                'application' = 'ApplicationName';
                                'application-group' = 'ApplicationGroupName';
                                'environment' = 'EnvironmentName';
                                'server' = 'ServerName';
                                'role' = 'ServerRoleName';
                            }

        $endpointName = 'variables/{0}' -f $PSCmdlet.ParameterSetName
        if( $PSCmdlet.ParameterSetName -ne 'global' )
        {
            $entityParamName = $entityParamNames[$PSCmdlet.ParameterSetName]
            $entityName = $PSBoundParameters[$entityParamName]
            $endpointName = '{0}/{1}' -f $endpointName,$entityName
        }

        $encodedName = $Name
        $endpointName = '{0}/{1}' -f $endpointName,$encodedName
        Invoke-BMRestMethod -Session $Session -Name $endpointName -Method Delete
    }

}