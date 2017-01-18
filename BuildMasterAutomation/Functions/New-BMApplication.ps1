
function New-BMApplication
{
    <#
    .SYNOPSIS
    Creates an application in BuildMaster.

    .DESCRIPTION
    The `New-BMApplication` function creates an application in BuildMaster.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A session object that represents the BuildMaster instance to use. Use the `New-BMSession` function to create session objects.
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the application.
        $Name,

        [string]
        [ValidateSet('MajorMinorRevision','MajorMinor','DateBased')]
        # The name of the release number scheme. Should be one of:
        #
        # * `MajorMinorRevision`
        # * `MajorMinor`
        # * `DateBased`
        $ReleaseNumberSchemeName,

        [string]
        [ValidateSet('Unique','Sequential','DateTimeBased')]
        # The name of the build number scheme. Should be one of:
        #
        # * `Unique`
        # * `Sequential`
        # * `DateTimeBased`
        $BuildNumberSchemeName,

        [int]
        # The ID of the issue tracking provider the application should use.
        $IssueTrackerID,

        [Switch]
        # Allow multiple active releases.
        $AllowMultipleActiveRelease,

        [Switch]
        # Allow multiple active builds.
        $AllowMultipleActiveBuild,

        [int]
        # The ID of the application group the application should be part of.
        $AplicationGroupID
    )

    Set-StrictMode -Version 'Latest'

    $parameters = @{
                        'Application_Name' = $Name;
                   }

    Invoke-BMNativeApiMethod -Session $Session -Name 'Applications_CreateApplication' -Parameter $parameters
}