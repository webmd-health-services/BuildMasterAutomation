
function Get-BMApplicationGroup
{
    <#
    .SYNOPSIS
    Gets BuildMaster application groups.

    .DESCRIPTION
    The `Get-BMApplicationGroup` function gets all application groups from an instance of BuildMaster.

    To get a specific application group, pass its id, name (wildcards supported), or an application group object to the
    `ApplicationGroup` parameter, or pipe them into the function. If the application group isn't found, the function
    writes an error.

    .EXAMPLE
    Get-BMApplicationGroup -Session $session

    Demonstrates how to get all BuildMaster application groups.

    .EXAMPLE
    Get-BMApplicationGroup -Session $session -ApplicationGroup 'My Application Group'

    Demonstrates how to get a specific application group.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The application group to get. Pass an id, name (wildcards supported), or application group object.
        [Parameter(ValueFromPipeline)]
        [Object] $ApplicationGroup
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false

        $appGroups = @()
        $appGroupName = $ApplicationGroup | Get-BMObjectName -Strict -ErrorAction Ignore
        Invoke-BMNativeApiMethod -Session $Session -Name 'ApplicationGroups_GetApplicationGroups' -Method Post |
            Where-Object {
                if( $appGroupName )
                {
                    return $_.ApplicationGroup_Name -like $appGroupName
                }

                return $true
            } |
            Tee-Object -Variable 'appGroups' |
            Write-Output

        $searching = $appGroupName -and [wildcardpattern]::ContainsWildcardCharacters($appGroupName)
        if ($ApplicationGroup -and -not $appGroups -and -not $searching)
        {
            $msg = "Application group ""$($appGroupName)"" does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}
