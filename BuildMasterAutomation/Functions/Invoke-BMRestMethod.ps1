
function Invoke-BMRestMethod
{
    <#
    .SYNOPSIS
    Invokes a BuildMaster REST method.

    .DESCRIPTION
    The `Invoke-BMRestMethod` invokes a BuildMaster REST API method. You pass the path to the endpoint (everything after
    `/api/`) via the `Name` parameter, the HTTP method to use via the `Method` parameter, and the parameters to pass in
    the body of the request via the `Parameter` parameter.  This function converts the `Parameter` hashtable to a
    URL-encoded query string and sends it in the body of the request. You can send the parameters as JSON by adding the
    `AsJson` parameter. You can pass your own custom body to the `Body` parameter. If you do, make sure you set an
    appropriate content type for the request with the `ContentType` parameter.

    You also need to pass an object that represents the BuildMaster instance and API key to use when connecting via the
    `Session` parameter. Use the `New-BMSession` function to create a session object.

    When using the `WhatIf` parameter, only web requests that use the `Get` HTTP method are made.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='NoBody')]
    param(
        # A session object to BuildMaster. Use the `New-BMSession` function to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the API to use. The should be everything after `/api/` in the method's URI.
        [Parameter(Mandatory)]
        [String] $Name,

        # The HTTP/web method to use. The default is `GET`.
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method =
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        # That parameters to pass to the method. These are converted to JSON and sent to the API in the body of the
        # request.
        [Parameter(Mandatory, ParameterSetName='BodyFromHashtable')]
        [hashtable] $Parameter,

        # Send the request as JSON. Otherwise, the data is sent as name/value pairs.
        [Parameter(ParameterSetName='BodyFromHashtable')]
        [switch] $AsJson,

        # The body to send.
        [Parameter(Mandatory, ParameterSetName='CustomBody')]
        [String] $Body,

        # The content type of the web request.
        #
        # By default,
        #
        # * if passing a value to the `Parameter` parameter, the content type is set to
        # `application/x-www-form-urlencoded`
        # * if passing a value to the `Parameter` parameter and you're using the `AsJson` switch, the content type is
        # set to `application/json`.
        #
        # Otherwise, the content type is not set. If you're passing your own body to the `Body` parameter, you may have
        # to set the appropriate content type for BuildMaster to respond.
        [String] $ContentType
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $uri = '{0}api/{1}' -f $Session.Url,$Name

    $debugBody = ''
    $webRequestParam = @{ }
    if( $Body )
    {
        $webRequestParam['Body'] = $Body
    }
    elseif( $Parameter )
    {
        if( $AsJson )
        {
            $Body = $Parameter | ConvertTo-Json -Depth 100
            $debugBody = $Body -replace '("API_Key": +")[^"]+','$1********'
            $encryptionKeyRegex = '"encryptionKey":( +)"([^"]+)"'
            if( $debugBody -match $encryptionKeyRegex )
            {
                $maskLength = $Matches[2].Length
                $mask = '*' * $maskLength
                $debugBody = $debugBody -replace $encryptionKeyRegex,('"encryptionKey":$1"{0}"' -f $mask)
            }
            if( -not $ContentType )
            {
                $ContentType = 'application/json; charset=utf-8'
            }
        }
        else
        {
            $bodyBuilder = [Text.StringBuilder]::New()
            $valueToMask = ''
            foreach ($paramName in $Parameter.Keys)
            {
                $paramValue = $Parameter[$paramName]
                if ($bodyBuilder.Length -gt 0)
                {
                    [void]$bodyBuilder.Append('&')
                }
                [void]$bodyBuilder.Append([Web.HttpUtility]::UrlEncode($paramName))
                [void]$bodyBuilder.Append('=')
                [void]$bodyBuilder.Append([Web.HttpUtility]::UrlEncode($paramValue))

                if ($paramName -eq 'API_Key')
                {
                    $valueToMask = $paramValue
                }
            }
            $Body = $bodyBuilder.ToString()
            $debugBody = $Body
            if ($valueToMask)
            {
                $debugBody = $debugBody -replace [regex]::Escape($valueToMask), '********'

            }

            if( -not $ContentType )
            {
                $ContentType = 'application/x-www-form-urlencoded; charset=utf-8'
            }
        }
        $webRequestParam['Body'] = $Body
    }

    if( $ContentType )
    {
        $webRequestParam['ContentType'] = $ContentType
    }

    $headers = @{
                    'X-ApiKey' = $Session.ApiKey;
                }

    #$DebugPreference = 'Continue'
    Write-Debug -Message ('{0} {1}' -f $Method.ToString().ToUpperInvariant(),($uri -replace '\b(API_Key=)([^&]+)','$1********'))
    if( $ContentType )
    {
        Write-Debug -Message ('Content-Type: {0}' -f $ContentType)
    }
    foreach( $headerName in $headers.Keys )
    {
        $value = $headers[$headerName]
        if( $headerName -eq 'X-ApiKey' )
        {
            $value = '*' * 8
        }

        Write-Debug -Message ('{0}: {1}' -f $headerName,$value)
    }

    if ($debugBody)
    {
        ($debugBody -split ([regex]::Escape([Environment]::NewLine))) | Write-Debug
    }

    try
    {
        if( $Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get -or $PSCmdlet.ShouldProcess($Uri,$Method) )
        {
            Invoke-RestMethod -Method $Method -Uri $uri @webRequestParam -Headers $headers |
                ForEach-Object { $_ } |
                Where-Object { $_ }
        }
    }
    catch
    {
        $Global:Error.RemoveAt(0)
        Write-Error -ErrorRecord $_ -ErrorAction $ErrorActionPreference
    }
}