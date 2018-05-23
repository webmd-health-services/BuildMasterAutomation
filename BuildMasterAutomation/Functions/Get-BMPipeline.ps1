
function Get-BMPipeline
{
    <#
    .SYNOPSIS
    Gets pipelines.

    .DESCRIPTION
    The `Get-BMPipeline` function gets pipelines. By default, it returns all pipelines. To get a specific pipeline, pass its name to the `Name` parameter or its ID to the `ID` parameter. The `Name` parameter supports wildcards. To get a specific application's pipelines, pass the application's ID to the `ApplicationID` parameter.

    This function uses the `Pipelines_GetPipelines` and `Pipelines_GetPipeline` native API methods.

    .EXAMPLE
    Get-BMPipeline -Session $session

    Demonstrates how to get all the pipelines.

    .EXAMPLE
    Get-BMPipeline -Session $session -Name 'BuildMaster Automation'

    Demonstrates how to get pipelines by name. If there are multiple pipelines with the same name, they will all be returned.

    .EXAMPLE
    Get-BMPipeline -Session $session -Name '*Automation'

    Demonstrates that you can use wildcards in the `Name` parameter's value to search for pipelines.
    
    .EXAMPLE
    Get-BMPipeline -Session $session -ID 34

    Demonstrates how to get a specific pipeline by its ID.
    
    .EXAMPLE
    Get-BMPipeline -Session $session -ApplicationID 39

    Demonstrates how to get a specific application's pipelines.
    
    .EXAMPLE
    Get-BMPipeline -Session $session -ApplicationID 39 -Name 'Pipeline 2'

    Demonstrates how to get an application's pipeline by its name.
    #>
    [CmdletBinding(DefaultParameterSetName='Searching')]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that represents the instance of BuildMaster to connect to. Use the `New-BMSession` function to creates a session object.
        $Session,

        [Parameter(ParameterSetName='Searching')]
        [string]
        # The name of the pipeline to get. Supports wildcards.
        $Name,

        [Parameter(ParameterSetName='Searching')]
        [int]
        # The ID of the application whose pipelines to get. The default is to return all pipelines.
        $ApplicationID,

        [Parameter(Mandatory=$true,ParameterSetName='SpecificPipeline')]
        [int]
        # The ID of the pipeline to get.
        $ID
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameter = @{ }
    $methodName = 'Pipelines_GetPipelines'
    if( $PSCmdlet.ParameterSetName -eq 'SpecificPipeline' )
    {
        $methodName = 'Pipelines_GetPipeline'
        $parameter['Pipeline_Id'] = $ID
    }
    else
    {
        if( $ApplicationID )
        {
            $parameter['Application_Id'] = $ApplicationID
        }
    }

    Invoke-BMNativeApiMethod -Session $session -Name $methodName -Parameter $parameter |
        Where-Object {
            if( $Name )
            {
                return ($_.Pipeline_Name -like $Name)
            }
            
            return $true
        }
}
