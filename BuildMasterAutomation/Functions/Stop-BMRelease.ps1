 function Stop-BMRelease
{
    <#
    .SYNOPSIS
    Cancels a release.

    .DESCRIPTION
    The `Stop-BMRelease` function cancels a BuildMaster release. It calls the `Releases_CancelRelease` native API
    endpoint. Pass the application name, id, or application object to the `Application` parameter and the release
    number to the `Number parameter. You can optionally provide a reason for cancelling the release by using the
    `Release` parameter.

    .EXAMPLE
    Stop-BMRelease -Session $session -Application 11 -Number 1.1

    Demonstrates how to cancel a release. In this case, the `1.1` release of the application whose ID is `11` is
    cancelled.

    .EXAMPLE
    Stop-BMRelease -Session $session -Application 'BuildMaster Automation' -Number 1.1

    Demonstrates how to cancel a release. In this case, the `1.1` release of the `BuildMaster Automation` application is
    cancelled.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The application name, id, or application object that should be cancelled.
        [Parameter(Mandatory)]
        [Alias('ApplicationID')]
        [Object] $Application,

        # The release number, e.g. 1, 2, 3, 1.0, 2.0, etc.
        [Parameter(Mandatory)]
        [String] $Number,

        # The reason for cancelling the release.
        [String] $Reason
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $bmApp = $Application | Get-BMApplication -Session $Session
    if (-not $bmApp)
    {
        return
    }

    $parameter = @{
            Application_Id = $bmApp.Application_Id;
            Release_Number = $Number;
            CancelledReason_Text = $Reason;
        }

    Invoke-BMNativeApiMethod -Session $Session -Name 'Releases_CancelRelease' -Parameter $parameter -Method Post
}