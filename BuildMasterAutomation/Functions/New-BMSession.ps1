
function New-BMSession
{
    <#
    .SYNOPSIS
    Creates a session object used to communicate with a BuildMaster instance.

    .DESCRIPTION
    The `New-BMSession` function creates and returns a session object that is required by any function in the
    BuildMasterAutomation module that communicates with BuildMaster. The session includes BuildMaster's URL and the
    credentials to use when making requests to BuildMaster's APIs

    .EXAMPLE
    $session = New-BMSession -Url 'https://buildmaster.com' -Credential $credential

    Demonstrates how to call `New-BMSession`. In this case, the returned session object can be passed to other
    BuildMasterAutomation module functions to communicate with BuildMaster at `https://buildmaster.com` with the
    credential in `$credential`.
    #>
    [CmdletBinding()]
    param(
        # The URI to the BuildMaster instance to use.
        [Parameter(Mandatory)]
        [Uri] $Url,

        # The API key to use when making requests to BuildMaster.
        [Parameter(Mandatory)]
        [String] $ApiKey
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    return [pscustomobject]@{
                                Url = $Url;
                                ApiKey = $ApiKey;
                            }
}