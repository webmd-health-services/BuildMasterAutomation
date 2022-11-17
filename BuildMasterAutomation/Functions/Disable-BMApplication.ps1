
function Disable-BMApplication
{
    <#
    .SYNOPSIS
    Disables a BuildMaster application

    .DESCRIPTION
    The `Disable-BMApplication` function disables an application in BuildMaster, which removes the application from the
    BuildMaster UI and reports. Pass the application name, id, or application object to the `Application` parameter. Or,
    pipe the name, id, or applicatoin object into the function.

    This function uses the native API, which can change without notice between releases. The API key you use must have
    access to the native API.

    .EXAMPLE
    Disable-BMApplication -Session $session -Application 494

    Demonstrates how to delete an application using its ID.

    .EXAMPLE
    'Disable Me!' | Get-BMApplication -Session $session | Disable-BMApplication -Session $session

    Demonstrates that you can pipe applications into `Disable-BMApplication`.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The application to get. Pass an application name, id, or application object.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('ID')]
        [Object] $Application
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $bmApp = $Application | Get-BMApplication -Session $Session
        if (-not $bmApp)
        {
            return
        }

        $deactivateParams = @{} | Add-BMObjectParameter -Name 'Application' -Value $bmApp -AsID -ForNativeApi -PassThru
        Invoke-BMNativeApiMethod -Session $Session `
                                 -Name 'Applications_DeactivateApplication' `
                                 -Parameter $deactivateParams `
                                 -Method Post
    }
}
