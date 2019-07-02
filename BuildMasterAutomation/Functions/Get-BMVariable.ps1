
function Get-BMVariable
{
    <#
    .SYNOPSIS
    Gets BuildMaster variables.

    .DESCRIPTION
    The `Get-BMVariable` function gets BuildMaster variables. By default, it gets all global variables. It can also get all variables for a specific environment, server, server role, application group, and application variables.

    To get a specific variable, pass the variable's name to the `Name` parameter. The default is to return all variables for the specific entity you've chosen (the default is global variables).
    
    To get an environment's variables, pass the environment's name to the `EnvironmentName` parameter.

    To get a server role's variables, pass the server role's name to the `ServerRoleName` parameter.

    To get a server's variables, pass the server's name to the `ServerName` parameter.

    To get an application group's variables, pass the application group's name to the `ApplicationGroupName` parameter.

    To get an application's variables, pass the application's name to the `ApplicationName` parameter.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use `New-BMSession` to create a session object.

    This function uses BuildMaster's variables API. Due to a bug in BuildMaster, it uses the native API when reading application group and application variables.

    .EXAMPLE
    Get-BMVariable

    Demonstrates how to get all global variables.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' 

    Demonstrates how to get a specific global variable.

    .EXAMPLE
    Get-BMVariable -Session $session -EnvironmentName 'Dev'

    Demonstrates how to all an environment's variables.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -EnvironmentName 'Dev'

    Demonstrates how to get a specific variable in an environment.

    .EXAMPLE
    Get-BMVariable -Session $session -ServerRoleName 'WebApp'

    Demonstrates how to get all variables in a specific server role.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -ServerRoleName 'WebApp'

    Demonstrates how to get a specific variable in a server role.

    .EXAMPLE
    Get-BMVariable -Session $session -ServerName 'example.com'

    Demonstrates how to get all variables for a specific server.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -ServerName 'example.com'

    Demonstrates how to get a specific variable in a server.

    .EXAMPLE
    Get-BMVariable -Session $session -ApplicationGroupName 'WebApps'

    Demonstrates how to get all variables from a specific application group.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -ApplicationGroupName 'WebApps'

    Demonstrates how to get a specific variable from an application group.

    .EXAMPLE
    Get-BMVariable -Session $session -ApplicationName 'www'

    Demonstrates how to get all variables from a specific application.

    .EXAMPLE
    Get-BMVariable -Session $session -Name 'Var' -ApplicationName 'www'

    Demonstrates how to get a specific variable from an application.
    #>
    [CmdletBinding(DefaultParameterSetName='global')]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        # The name of the variable to get. The default is to get all global variables.
        [string]$Name,

        [Parameter(Mandatory,ParameterSetName='application')]
        # The name of the application where the variable or variables should be read. The default is to get global variables.
        [string]$ApplicationName,

        [Parameter(Mandatory,ParameterSetName='application-group')]
        # The name of the application group where the variable or variables should be read. The default is to get global variables.
        [string]$ApplicationGroupName,

        [Parameter(Mandatory,ParameterSetName='environment')]
        # The name of the environment where the variable or variables should be read. The default is to get global variables.
        [string]$EnvironmentName,

        [Parameter(Mandatory,ParameterSetName='server')]
        # The name of the server where the variable or variables should be read. The default is to get global variables.
        [string]$ServerName,

        [Parameter(Mandatory,ParameterSetName='role')]
        # The name of the server role where the variable or variables should be read. The default is to get global variables.
        [string]$ServerRoleName,

        # Return the variable's value, not an object representing the variable.
        [Switch]$ValueOnly
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

    $endpointName = 'variables/{0}' -f $PSCmdlet.ParameterSetName
    $entityName = ''
    if( $PSCmdlet.ParameterSetName -ne 'global' )
    {
        $entityParamName = $entityParamNames[$PSCmdlet.ParameterSetName]
        $entityName = $PSBoundParameters[$entityParamName]
        $encodedEntityName = [uri]::EscapeDataString($entityName)
        $endpointName = '{0}/{1}' -f $endpointName,$encodedEntityName
    }

    if( $PSCmdlet.ParameterSetName -in @( 'application', 'application-group' ) )
    {
        $appValues = @{ }
        & {
            $originalWhatIf = $WhatIfPreference
            $WhatIfPreference = $false
            try
            {
                if( $PSCmdlet.ParameterSetName -eq 'application' )
                {
                    $app = Get-BMApplication -Session $Session -Name $ApplicationName
                    Invoke-BMNativeApiMethod -Session $Session -Name 'Variables_GetVariablesForScope' -Method Post -Parameter @{ 'Application_Id' = $app.Application_Id } 
                }
                elseif( $PSCmdlet.ParameterSetName -eq 'application-group' )
                {
                    $appGroup = Get-BMApplicationGroup -Session $Session -Name $ApplicationGroupName
                    Invoke-BMNativeApiMethod -Session $Session -Name 'Variables_GetVariablesForScope' -Method Post -Parameter @{ 'ApplicationGroup_Id' = $appGroup.ApplicationGroup_Id } 
                }
            }
            finally
            {
            }
        } |
            ForEach-Object {
                $bytes = [Convert]::FromBase64String($_.Variable_Value)
                $appValues[$_.Variable_Name] = [Text.Encoding]::UTF8.GetString($bytes)
            }
        $values = [pscustomobject]$appValues
    }
    else
    {
        $values = Invoke-BMRestMethod -Session $Session -Name $endpointName
    }

    if( -not $values )
    {
        return
    }

    $foundVars = $null

    # Tee-Object supports WhatIfPreference.
    $originalWhatIf = $WhatIfPreference
    $WhatIfPreference = $false
    try
    {
        $values | 
            Get-Member -MemberType NoteProperty |
            ForEach-Object {
                $variableName = $_.Name
                [pscustomobject]@{ 
                                    Name = $variableName;
                                    Value = $values.$variableName
                                }
            } |
            Where-Object {
                if( $Name )
                {
                    return $_.Name -like $Name
                }
                return $true
            } |
            ForEach-Object {
                if( $ValueOnly )
                {
                    return $_.Value
                }
                return $_
            } | 
            Tee-Object -Variable 'foundVars'
    }
    finally
    {
        $WhatIfPreference = $originalWhatIf
    }

    if( $Name -and -not [wildcardpattern]::ContainsWildcardCharacters($Name) -and -not $foundVars )
    {
        $entityTypeDescriptions = @{
                                    'application' = 'application';
                                    'application-group' = 'application group';
                                    'environment' = 'environment';
                                    'server' = 'server';
                                    'role' = 'server role'
                              }

        $typeName = $entityTypeDescriptions[$PSCmdlet.ParameterSetName]
        if( $typeName )
        {
            $typeName = ' in {0}' -f $typeName
        }

        $entityNameDesc = ''
        if( $entityName )
        {
            $entityNameDesc = ' "{0}"' -f $entityName
        }
        Write-Error -Message ('Variable "{0}"{1}{2} does not exist.' -f $Name,$typeName,$entityNameDesc) -ErrorAction $ErrorActionPreference
    }
}