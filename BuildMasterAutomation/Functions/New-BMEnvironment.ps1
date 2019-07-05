
function New-BMEnvironment
{
    <#
    .SYNOPSIS
    Creates a new environment in a BuildMaster instance.

    .DESCRIPTION
    The `New-BMEnvironment` creates a new environment in BuildMaster. Pass the name of the environment to the `Name` parameter. Names may only contain letters, numbers, periods, underscores, or dashes and may not end with an underscore or dash.
    
    Every environment must have a unique name. If you create a environment with a duplicate name, you'll get an error.

    Environments can't be deleted. Deleted environments are just disabled/inactive. If you need to reactivate/enable a disabled environment, use `Enable-BMEnvironment`. If you try to create a new environment with the same name as an inactive environment, you'll get an error.
    
    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use the `New-BMSession` function to create session objects.

    This function uses BuildMaster's infrastructure management API.

    .EXAMPLE
    New-BMEnvironment -Session $session -Name 'DevNew'

    Demonstrates how to create a new environment.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9_-]*(?<![_-])$')]
        [ValidateLength(1,50)]
        # The name of the environment to create. Must contain only letters, numbers, underscores, or dashes. Must begin with a letter. Must not end with an underscore or dash. Must be between 1 and 50 characters long.
        [string]$Name,

        # The name of this environment's parent environemnt.
        [string]$ParentName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameter = @{
                    name = $Name;
                    parent = $ParentName;
                 }
    $encodedName = [uri]::EscapeDataString($Name)
    Invoke-BMRestMethod -Session $Session -Name ('infrastructure/environments/create/{0}' -f $encodedName) -Method Post -Parameter $parameter -AsJson
}