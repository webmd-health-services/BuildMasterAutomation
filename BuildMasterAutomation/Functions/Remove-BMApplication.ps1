
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
    Remove-BMApplication -Session $session -Application $app

    Demonstrates how to delete an application by passing an application object to the `Application` parameter.

    .EXAMPLE
    Remove-BMApplication -Session $session -Application 432

    Demonstrates how to delete an application by passing its id to the `Application` parameter.

    .EXAMPLE
    Remove-BMApplication -Session $session -Application 'So Long'

    Demonstrates how to delete an application by passing its name to the `Application` parameter.

    .EXAMPLE
    $app,433,'So Long 2' | Remove-BMApplication -Session $session

    Demonstrates that you can pipe application ids, names, and/or objects to `Remove-BMApplication`.

    .EXAMPLE
    Remove-BMApplication -Session $session -Application $app -Force

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

        $getDeleteParams =
            @{ } | Add-BMObjectParameter -Name 'Application' -Value $Application -ForNativeApi -PassThru

        $app = Invoke-BMNativeApiMethod -Session $Session `
                                        -Name 'Applications_GetApplication' `
                                        -Parameter $getDeleteParams `
                                        -Method Post

        if (-not $app)
        {
            $msg = "Cannot delete application ""$($Application | Get-BMObjectName)"" because it does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        if (-not $Force -and $app.Active_Indicator -eq 'Y')
        {
            $msg = "Application ""$($app.Application_Name)"" is active. Only inactive applications can be deleted. " +
                   'Use the "Disable-BMApplication" function to disable the application, or use the -Force (switch) ' +
                   'on this function to delete an active application.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }

        Invoke-BMNativeApiMethod -Session $Session `
                                 -Name 'Applications_PurgeApplicationData' `
                                 -Parameter $getDeleteParams `
                                 -Method Post |
            Out-Null
    }
}
