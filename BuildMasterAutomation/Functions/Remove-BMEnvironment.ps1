
function Remove-BMEnvironment
{
    <#
    .SYNOPSIS
    Deletes environments in BuildMaster.

    .DESCRIPTION
    The `Remove-BMEnvironment` function removes an environment from BuildMaster. Pass the environment's id, name, or
    object to the `Environment` parameter (or pipe them to `Remove-BMEnvironment`).

    Uses the BuildMaster
    [Infrastructure Management API](https://docs.inedo.com/docs/buildmaster-reference-api-infrastructure).

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
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The environment's id, name, or object to delete. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Environment
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

        $apiName = "infrastructure/environments/delete/$($env.name)"
        Invoke-BMRestMethod -Session $Session -Name $apiName -Method Delete | Out-Null
    }
}
