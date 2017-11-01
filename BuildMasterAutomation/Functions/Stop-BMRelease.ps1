 function Stop-BMRelease 
{
    <#
    .SYNOPSIS
    Cancels a release.

    .DESCRIPTION
    The `Stop-BMRelease` function cancels a BuildMaster release. It calls the `Releases_CancelRelease` native API endpoint.

    .EXAMPLE
    Stop-BMRelease -Session $session -Application 11 -Number 1.1

    Demonstrates how to cancel a release. In this case, the `1.1` release of the application whose ID is `11` is cancelled.

    .EXAMPLE
    Stop-BMRelease -Session $session -Application 'BuildMaster Automation' -Number 1.1

    Demonstrates how to cancel a release. In this case, the `1.1` release of the `BuildMaster Automation` application is cancelled.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The session to use when connecting to BuildMaster. Use `New-BMSession` to create session objects. 
        $Session,

        [Parameter(Mandatory=$true)]
        [int]
        # The ID of the application whose release should be cancelled. 
        $ApplicationID,

        [Parameter(Mandatory=$true)]
        [string]
        # The release number, e.g. 1, 2, 3, 1.0, 2.0, etc.
        $Number,

        [string]
        # The reason for cancelling the release.
        $Reason
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameter = @{
                    Application_Id = $ApplicationID;
                    Release_Number = $Number;
                    CancelledReason_Text = $Reason
                }

    Invoke-BMNativeApiMethod -Session $Session -Name 'Releases_CancelRelease' -Parameter $parameter -Method Post
}