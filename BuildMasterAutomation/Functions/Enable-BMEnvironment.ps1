
function Enable-BMEnvironment
{
    <#
    .SYNOPSIS
    Enable an environment in BuildMaster.

    .DESCRIPTION
    The `Enable-BMEnvironment` function enables an environment in BuildMaster. Environments are permanent and can only be disabled, never deleted. Pass the name of the environment to enable to the `Name` parameter. If the environment doesn't exist, you'll get an error.

    Pass the session to the BuildMaster instance where you want to enable the environment to the `Session` parameter. Use `New-BMSession` to create a session object.

    This function uses BuildMaster's native and infrastructure APIs.

    .EXAMPLE
    Enable-BMEnvironment -Session $session -Name 'Dev'

    Demonstrates how to enable an environment

    .EXAMPLE
    Get-BMEnvironment -Session $session -Name 'DevOld' -Force | Enable-BMEnvironment -Session $session

    Demonstrates that you can pipe the objects returned by `Get-BMEnvironment` into `Enable-BMEnvironment` to enable those environments.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "")]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        [Parameter(Mandatory, ValueFromPipeline)]
        # The environment to enable. Pass an id, name, or an environment object.
        [Object] $Environment
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $Environment = $Environment | Get-BMEnvironment -Session $Session -Force
        if (-not $Environment -or $Environment.active)
        {
            return
        }

        $parameter = @{} | Add-BMObjectParameter -Name 'Environment' -Value $Environment -ForNativeApi -PassThru
        Invoke-BMNativeApiMethod -Session $session `
                                    -Name 'Environments_UndeleteEnvironment' `
                                    -Parameter $parameter `
                                    -Method Post
    }
}