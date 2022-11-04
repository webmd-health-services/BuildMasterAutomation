
function Get-BMEnvironment
{
    <#
    .SYNOPSIS
    Returns environments from a BuildMaster instance.

    .DESCRIPTION
    The `Get-BMEnvironment` function gets all the environments from an instance of BuildMaster. By default, this function returns all active environments. Use the `Force` switch to return inactive environments, too.

    To return a specific environment (even one that's inactive), pass its name to the `Name` parameter. If an environment with the given name doesn't exist, you'll get an error. You can use wildcards to search for active environments. When searching for an environment with wildcards, inactive environments are not searched. Use the `Force` switch to include inactive environments in the search.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use `New-BMSession` to create a session object.

    This function uses BuildMaster's native APIs.

    .EXAMPLE
    Get-BMEnvironment

    Demonstrates how to return a list of all BuildMaster active environments.

    .EXAMPLE
    Get-BMEnvironment -Force

    Demonstrates how to return a list of all active *and* inactive BuildMaster environments.

    .EXAMPLE
    Get-BMEnvironment -Name '*Dev*'

    Demonstrates how to use wildcards to search for active environments.

    .EXAMPLE
    Get-BMEnvironment -Name '*Dev*' -Force

    Demonstrates how to use wildcards to search for active *and* inactive environments.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the environment to return. If one doesn't exist, you'll get an error. You may search for environments by using wildcards. If no environments match the wildcard pattern, no error is returned. When searching with wildcards, only active environments are searched. Use the `Force` switch to also search inactive environments.
        [Parameter(ValueFromPipeline)]
        [Alias('Name')]
        [Object] $Environment,

        # By default, inactive/disabled environments are not returned. Use the `Force` to return inactive environments,
        # too.
        [switch] $Force
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $environments = $null

        $environmentName = $Environment | Get-BMObjectName -Strict -ErrorAction Ignore
        $searching = $environmentName -and [wildcardpattern]::ContainsWildcardCharacters($environmentName)

        # The Native API uses POST, which is interpreted as a data-modification, so
        # is subject to the user's WhatIfPreference. Since we know this method
        # doesn't modify data, disable WhatIf.
        $WhatIfPreference = $false

        # There's no way to get inactive environments from BuildMaster's infrastructure API so we have to use the native API. :(
        Invoke-BMNativeApiMethod -Session $session -Name 'Environments_GetEnvironments' -Parameter @{ IncludeInactive_Indicator = $true } -Method Post |
            ForEach-Object {
                [pscustomobject]@{
                                    id = $_.Environment_Id;
                                    name = $_.Environment_Name;
                                    active = $_.Active_Indicator;
                                    parentName = $_.Parent_Environment_Name;
                                }
            } |
            Where-Object {
                # Only return environments that match the user's search.
                if ($environmentName)
                {
                    return $_.name -like $environmentName
                }
                return $true
            } |
            Where-Object {
                # Only return active environments unless the user is using the Force or retrieving a specific
                # environment.
                if ($Force -or ($Environment -and -not $searching))
                {
                    return $true
                }
                return $_.active
            } |
            Tee-Object -Variable 'environments'

        if ($Environment -and -not $environments -and -not $searching)
        {
            $msg = "Environment ""$($Environment | Get-BMObjectName)"" does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}