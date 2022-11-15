
function Remove-BMApplication
{
    <#
    .SYNOPSIS
    Deletes applications in BuildMaster.

    .DESCRIPTION
    The `Remove-BMApplication` function removes an application from BuildMaster. Pass the application's id, name, or
    object to the `Application` parameter. If the application is disabled, it will be deleted. To delete the application
    even if it's still enabled, use the `Force` (switch).

    Use `Disable-BMApplication` to disable an application.

    Uses the BuildMaster native API.

    .EXAMPLE
    Remove-BMApplication -Session $session -Application $bmApp

    Demonstrates how to delete an application by passing an application object to the `Application` parameter.

    .EXAMPLE
    Remove-BMApplication -Session $session -Application 432

    Demonstrates how to delete an application by passing its id to the `Application` parameter.

    .EXAMPLE
    Remove-BMApplication -Session $session -Application 'So Long'

    Demonstrates how to delete an application by passing its name to the `Application` parameter.

    .EXAMPLE
    $bmApp,433,'So Long 2' | Remove-BMApplication -Session $session

    Demonstrates that you can pipe application ids, names, and/or objects to `Remove-BMApplication`.

    .EXAMPLE
    Remove-BMApplication -Session $session -Application $bmApp -Force

    Demonstrates how to delete an application even if its still enabled by using the `Force` (switch).
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The application's id, name, or object to delete. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Application,

        # If set, will delete an active application.
        [switch] $Force
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $bmApp = $Application | Get-BMApplication -Session $Session -ErrorAction Ignore
        if (-not $bmApp)
        {
            $msg = "Cannot delete application ""$($Application | Get-BMObjectName)"" because it does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        if (-not $Force -and $bmApp.Active_Indicator -eq 'Y')
        {
            $msg = "Cannot delete application ""$($bmApp.Application_Name)"" because it is active. Use the " +
                   '"Disable-BMApplication" function to disable the application then delete it, or use this ' +
                   'function''s -Force (switch) to delete this active application.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $appArg = @{} | Add-BMObjectParameter -Name 'Application' -Value $bmApp -ForNativeApi -PassThru
        Invoke-BMNativeApiMethod -Session $Session `
                                 -Name 'Applications_PurgeApplicationData' `
                                 -Parameter $appArg `
                                 -Method Post |
            Out-Null
    }
}
