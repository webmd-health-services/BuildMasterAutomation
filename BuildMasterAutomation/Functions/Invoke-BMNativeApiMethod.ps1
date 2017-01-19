
function Invoke-BMNativeApiMethod
{
    <#
    .SYNOPSIS
    Calls a method on BuildMaster's "native" API.

    .DESCRIPTION
    The `Invoke-BMNativeApiMethod` calls a method on BuildMaster's "native" API. From Inedo:

    > This API endpoint should be avoided if there is an alternate API endpoint available, as those are much easier to use and will likely not change.

    In other words, use a native API at your own peril.

    .EXAMPLE
    Invoke-BMNativeApiMethod -Session $session -Name 'Applications_CreateApplication' -Parameter @{ Application_Name = 'fubar' }

    Demonstrates how to call `Invoke-BMNativeApiMethod`. In this example, it is calling the `Applications_CreateApplication` method to create a new application named `fubar`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A session object that represents the BuildMaster instance to use. Use the `New-BMSession` function to create session objects.
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the API method to use. The list can be found at http://inedo.com/support/documentation/buildmaster/reference/api/native, or under your local BuildMaster instance at /reference/api
        $Name,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        # The HTTP/web method to use. The default is `POST`.
        $Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Parameter
    )

    Set-StrictMode -Version 'Latest'

    $uri = '{0}api/json/{1}' -f $Session.Uri,$Name,$Session.ApiKey
    
    $body = $Parameter | ConvertTo-Json -Depth ([int32]::MaxValue)

    $contentType = 'application/json; charset=utf-8'

    $headers = @{
                    'X-ApiKey' = $Session.ApiKey;
                }

    $DebugPreference = 'Continue'
    Write-Debug -Message ('{0} {1}' -f $Method.ToString().ToUpperInvariant(),($uri -replace '\b(API_Key=)([^&]+)','$1********'))
    Write-Debug -Message ('Content-Type: {0}' -f $contentType)
    foreach( $headerName in $headers.Keys )
    {
        $value = $headers[$headerName]
        if( $headerName -eq 'X-ApiKey' )
        {
            $value = '*' * 8
        }

        Write-Debug -Message ('{0}: {1}' -f $headerName,$value)
    }
    Write-Debug -Message ($body -replace '("API_Key": +")[^"]+','$1********')

    try
    {
        Invoke-RestMethod -Method $Method -Uri $uri -Body $body -ContentType $contentType -Headers $headers | ForEach-Object { $_ } 
    }
    catch [Net.WebException]
    {
        Write-Error -ErrorRecord $_
    }

}