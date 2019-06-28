
function Disable-BMEnvironment
{
    <#
    .SYNOPSIS
    Disable an environment in BuildMaster.

    .DESCRIPTION
    The `Disable-BMEnvironment` function disables an environment in BuildMaster. Environments are permanent can only be disabled, never deleted. Pass the name of the environment to disable to the `Name` parameter. If the environment doesn't exist, you'll get an error.

    Pass the session to the BuildMaster instance where you want to disable the environment to the `Session` parameter. Use `New-BMSession` to create a session object.

    This function uses BuildMaster's infrastructure management API.

    .EXAMPLE
    Disable-BMEnvironment -Session $session -Name 'Dev'

    Demonstrates how to disable an environment

    .EXAMPLE
    Get-BMEnvironment -Session $session -Name 'DevOld' | Disable-BMEnvironment -Session $session

    Demonstrates that you can pipe the objects returned by `Get-BMEnvironment` into `Disable-BMEnvironment` to disable those environments.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        # An object representing the instance of BuildMaster to connect to. Use `New-BMSession` to create session objects.
        [object]$Session,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        # The name of the environment to disable.
        [string]$Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $environment = Get-BMEnvironment -Session $Session -Name $Name -Force
        if( $environment -and $environment.active )
        {
            Invoke-BMNativeApiMethod -Session $session -Name 'Environments_DeleteEnvironment' -Parameter @{ 'Environment_Id' = $environment.id } -Method Post
        }
    }
}