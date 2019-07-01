
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
    [CmdletBinding(DefaultParameterSetName='global')]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory)]
        # The name of the variable to create.
        [string]$Name,

        [Parameter(Mandatory)]
        # The variable's value. Passed to BuildMaster as-is.
        [string]$Value,

        [Parameter(Mandatory,ParameterSetName='application')]
        # The name of the application where the variable should be created. The default is to create a global variable.
        [string]$ApplicationName,

        [Parameter(Mandatory,ParameterSetName='application-group')]
        # The name of the application group where the variable should be created. The default is to create a global variable.
        [string]$ApplicationGroupName,

        [Parameter(Mandatory,ParameterSetName='environment')]
        # The name of the environment where the variable should be created. The default is to create a global variable.
        [string]$EnvironmentName,

        [Parameter(Mandatory,ParameterSetName='server')]
        # The name of the server where the variable should be created. The default is to create a global variable.
        [string]$ServerName,

        [Parameter(Mandatory,ParameterSetName='role')]
        # The name of the server role where the variable should be created. The default is to create a global variable.
        [string]$ServerRoleName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $entityParamNames = @{
                            'application' = 'ApplicationName';
                            'application-group' = 'ApplicationGroupName';
                            'environment' = 'EnvironmentName';
                            'server' = 'ServerName';
                            'role' = 'ServerRoleName';
                        }

    $endpointName = ('variables/{0}' -f $PSCmdlet.ParameterSetName)
    if( $PSCmdlet.ParameterSetName -ne 'global' )
    {
        $entityParamName = $entityParamNames[$PSCmdlet.ParameterSetName]
        $entityName = $PSBoundParameters[$entityParamName]
        $endpointName = '{0}/{1}' -f $endpointName,$entityName
    }
    $encodedName = $Name
    $endpointName = '{0}/{1}' -f $endpointName,$encodedName

    Invoke-BMRestMethod -Session $Session -Name $endpointName -Method Post -Body $Value
}