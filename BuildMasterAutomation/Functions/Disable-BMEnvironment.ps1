
function Disable-BMEnvironment
{
    <#
    .SYNOPSIS
    Disable an environment in BuildMaster.

    .DESCRIPTION
    The `Disable-BMEnvironment` function disables an environment in BuildMaster. Environments are permanent and can only be disabled, never deleted. Pass the name of the environment to disable to the `Name` parameter. If the environment doesn't exist, you'll get an error.

    Pass the session to the BuildMaster instance where you want to disable the environment to the `Session` parameter. Use `New-BMSession` to create a session object.

    This function uses BuildMaster's infrastructure management API.

    .EXAMPLE
    Disable-BMEnvironment -Session $session -Name 'Dev'

    Demonstrates how to disable an environment

    .EXAMPLE
    Get-BMEnvironment -Session $session -Name 'DevOld' | Disable-BMEnvironment -Session $session

    Demonstrates that you can pipe the objects returned by `Get-BMEnvironment` into `Disable-BMEnvironment` to disable those environments.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "")]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The environment to disable. Pass an environment id, name or an environment object.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Environment
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $Environment = $Environment | Get-BMEnvironment -Session $Session -Force
        if (-not $Environment -or -not $Environment.active)
        {
            return
        }

        $environmentArg = @{} | Add-BMObjectParameter -Name 'Environment' -Value $Environment -ForNativeApi -PassThru
        Invoke-BMNativeApiMethod -Session $session `
                                 -Name 'Environments_DeleteEnvironment' `
                                 -Parameter $environmentArg `
                                 -Method Post
    }
}