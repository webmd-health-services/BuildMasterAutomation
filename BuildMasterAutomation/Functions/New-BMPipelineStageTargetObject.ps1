
function New-BMPipelineStageTargetObject
{
    <#
    .SYNOPSIS
    Creates a stage target object that can be passed to the `New-BMPipelineStageObject` function.

    .DESCRIPTION
    The `New-BMPipelineStageTargetObject` function creates a pipeline stage target object. Pass the plan name to execute
    to the `PlanName` parameter. By default, creates an object that targets no servers.

    To target servers in a specific environment, pass the environment's name to the `EnvironmentName` parameter.

    To target all servers in an environment, use the `AllServers` switch. You must also pass an environment name.

    To target servers in specific roles, pass the role name(s) to the `ServerRoleName`.

    To target servers in specific server pools, pass the server pool names(s) to the `ServerPoolName` parameter.

    To target specific servers, pass the server name(s) to the `ServerName` parameter.

    .EXAMPLE
    New-BMPipelineStageTargetObject -PlanName 'Deploy'

    Demonstrates how to create a target object that executes a plan against no servers.

    .EXAMPLE
    New-BMPipelineStageTargetObject -PlanName 'Deploy' -EnvironmentName 'Integration'

    Demonstrates how to create a target object that executes a plan against servers in a specific environment. In this
    case, the `Integration` environment.

    .EXAMPLE
    New-BMPipelineStageTargetObject -PlanName 'Deploy' -EnvironmentName 'Integration' -ServerRoleName 'Build'

    Demonstrates how to create a target object that executes a plan against servers with a specific role. In this case,
    all servers with the `Build` role in the `Integration` environment will be targeted.

    .EXAMPLE
    New-BMPipelineStageTargetObject -PlanName 'Deploy' -EnvironmentName 'Integration' -ServerPoolName 'Build'

    Demonstrates how to create a target object that executes a plan against servers in a specific pool. In this case,
    all servers in the `Build` pool in the `Integration` environment will be targeted.

    .EXAMPLE
    New-BMPipelineStageTargetObject -PlanName 'Deploy' -EnvironmentName 'Integration' -AllServers

    Demonstrates how to create a target object that executes a plan against all servers in a specific environment. In
    this case, all servers in the `Integration` environment will be targeted.

    .EXAMPLE
    New-BMPipelineStageTargetObject -PlanName 'Deploy' -ServerName 'example.com'

    Demonstrates how to create a target object that executes a plan against a specific server. In this case, only the
    `example.com` server will be targed.
    #>
    [CmdletBinding(DefaultParameterSetName=0)]
    param(
        [Parameter(Mandatory)]
        [String] $PlanName,

        [Parameter(ParameterSetName=0)]
        [Parameter(ParameterSetName=1)]
        [Parameter(Mandatory, ParameterSetName=2)]
        [Parameter(ParameterSetName=3)]
        [Parameter(ParameterSetName=4)]
        [String] $EnvironmentName,

        [Parameter(Mandatory, ParameterSetName=1)]
        [String[]] $ServerName,

        [Parameter(Mandatory, ParameterSetName=2)]
        [switch] $AllServers,

        [Parameter(Mandatory, ParameterSetName=3)]
        [String[]] $ServerRoleName,

        [Parameter(Mandatory, ParameterSetName=4)]
        [String[]] $ServerPoolName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $target = [pscustomobject]@{
        PlanName = $PlanName;
        EnvironmentName = $EnvironmentName;
        ServerNames = @();
        ServerRoleNames = @();
    }

    if( $PSCmdlet.ParameterSetName -ne 0 )
    {
        if( $PSCmdlet.ParameterSetName -eq 1 )
        {
            $target.ServerNames = $ServerName
        }
        elseif( $PSCmdlet.ParameterSetName -eq 3 )
        {
            $target.ServerRoleNames = $ServerRoleName
        }
        elseif( $PSCmdlet.ParameterSetName -eq 4 )
        {
            $target.ServerRoleNames = $ServerPoolName
        }
        $target | Add-Member -Name 'DefaultServerContext' -Value $PSCmdlet.ParameterSetName -MemberType NoteProperty
    }

    return $target
}