
function Get-BMApplication
{
    <#
    .SYNOPSIS
    Gets the applications in BuildMaster.
    
    .DESCRIPTION
    Gets the applications in BuildMaster.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The session to use when connecting to BuildMaster.
        $Session,

        [string]
        # The name of the application to get.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    $parameters = @{
                        Application_Count = $null;
                        IncludeInactive_Indicator = 'Y';
                   } 

    Invoke-BMNativeApiMethod -Session $Session -Name 'Applications_GetApplications' -Parameter $parameters
}
