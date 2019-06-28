
function Enable-BMEnvironment
{
    <#
    .SYNOPSIS
    Enable an environment in BuildMaster.

    .DESCRIPTION
    The `Enable-BMEnvironment` function enabless an environment in BuildMaster. Environments are permanent and can only be disabled, never deleted. Pass the name of the environment to enable to the `Name` parameter. If the environment doesn't exist, you'll get an error.

    Pass the session to the BuildMaster instance where you want to enable the environment to the `Session` parameter. Use `New-BMSession` to create a session object.

    This function uses BuildMaster's native and infrastructure APIs.

    .EXAMPLE
    Enable-BMEnvironment -Session $session -Name 'Dev'

    Demonstrates how to enable an environment

    .EXAMPLE
    Get-BMEnvironment -Session $session -Name 'DevOld' | Enable-BMEnvironment -Session $session

    Demonstrates that you can pipe the objects returned by `Get-BMEnvironment` into `Enable-BMEnvironment` to enable those environments.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        # The name of the environment to enable.
        [string]$Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $environment = Get-BMEnvironment -Session $Session -Name $Name -Force
        if( $environment -and -not $environment.active )
        {
            Invoke-BMNativeApiMethod -Session $session -Name 'Environments_UndeleteEnvironment' -Parameter @{ 'Environment_Id' = $environment.id } -Method Post
        }
    }
}