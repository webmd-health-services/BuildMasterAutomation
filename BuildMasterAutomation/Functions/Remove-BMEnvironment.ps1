
function Remove-BMEnvironment
{
    <#
    .SYNOPSIS
    Deletes environments in BuildMaster.

    .DESCRIPTION
    The `Remove-BMEnvironment` function removes an environment from BuildMaster. Pass the environment's id, name, or
    object to the `Environment` parameter (or pipe them to `Remove-BMEnvironment`). If the environment is disabled, it
    will be deleted. To delete the environment even if it's still enabled, use the `Force` (switch).

    Use `Disable-BMEnvironment` to disable an environment.

    Uses the BuildMaster native API.

    .EXAMPLE
    Remove-BMEnvironment -Session $session -Environment $env

    Demonstrates how to delete an environment by passing an environment object to the `Environment` parameter.

    .EXAMPLE
    Remove-BMEnvironment -Session $session -Environment 432

    Demonstrates how to delete an environment by passing its id to the `Environment` parameter.

    .EXAMPLE
    Remove-BMEnvironment -Session $session -Environment 'So Long'

    Demonstrates how to delete an environment by passing its name to the `Environment` parameter.

    .EXAMPLE
    $env,433,'So Long 2' | Remove-BMEnvironment -Session $session

    Demonstrates that you can pipe environment ids, names, and/or objects to `Remove-BMEnvironment`.

    .EXAMPLE
    Remove-BMEnvironment -Session $session -Environment $env -Force

    Demonstrates how to delete an environment even if its still enabled by using the `Force` (switch).
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The environment's id, name, or object to delete. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Environment,

        # If set, will delete an environment even if it is active.
        [switch] $Force
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $env = $Environment | Get-BMEnvironment -Session $Session -ErrorAction Ignore
        if (-not $env)
        {
            $msg = "Cannot delete environment ""$($env | Get-BMObjectName)"" because it does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        if (-not $Force -and $env.Ative_Indicator -eq 'Y')
        {
            $msg = "Environment ""$($env | Get-BmObjectName)"" is active. Only inactive environments can be deleted. " +
                   'Use the "Disable-BMEnvironment" function to disable the application, or use the -Force (switch) ' +
                   'on this function to delete an active environment.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }

        $appArg =
            @{} |
            Add-BMObjectParameter -Name 'Environment' -Value $env -AsID -ForNativeApi -PassThru |
            Add-BMParameter -Name 'Purge' -Value 'Y' -PassThru
        Invoke-BMNativeApiMethod -Session $Session `
                                 -Name 'Environments_DeleteEnvironment' `
                                 -Parameter $appArg `
                                 -Method Post |
            Out-Null
    }
}
