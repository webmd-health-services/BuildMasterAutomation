
function Invoke-BMNativeApiMethod
{
    <#
    .SYNOPSIS
    Calls a method on BuildMaster's "native" API.

    .DESCRIPTION
    The `Invoke-BMNativeApiMethod` calls a method on BuildMaster's "native" API. From Inedo:

    > This API endpoint should be avoided if there is an alternate API endpoint available, as those are much easier to
    > use and will likely not change.

    In other words, use a native API at your own peril.

    When using the `WhatIf` parameter, only web requests that use the `Get` HTTP method are made.

    .EXAMPLE
    Invoke-BMNativeApiMethod -Session $session -Name 'Applications_CreateApplication' -Parameter @{ Application_Name = 'fubar' }

    Demonstrates how to call `Invoke-BMNativeApiMethod`. In this example, it is calling the
    `Applications_CreateApplication` method to create a new application named `fubar`.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the API method to use. The list can be found at
        # http://inedo.com/support/documentation/buildmaster/reference/api/native, or under your local BuildMaster
        # instance at /reference/api
        [Parameter(Mandatory)]
        [String] $Name,

        # The HTTP/web method to use. The default is `GET`.
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method =
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        # Any parameters to pass to the endpoint. The keys/values are sent in the body of the request as a JSON object.
        [hashtable] $Parameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameterParam = @{ }
    if( $Parameter -and $Parameter.Count )
    {
        $parameterParam['Parameter'] = $Parameter
        $parameterParam['AsJson'] = $true
    }

    Invoke-BMRestMethod -Session $Session -Name ('json/{0}' -f $Name) -Method $Method @parameterParam
}