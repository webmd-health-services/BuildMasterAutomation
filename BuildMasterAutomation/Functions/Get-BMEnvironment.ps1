
function Get-BMEnvironment
{
    <#
    .SYNOPSIS
    Returns environments from a BuildMaster instance.

    .DESCRIPTION
    The `Get-BMEnvironment` function gets all the environments from an instance of BuildMaster.

    To return a specific environment, pass its name to the `Name` parameter. If an environment with the given name
    doesn't exist, you'll get an error. You can use wildcards to search for active environments.

    Pass a session object representing the instance of BuildMaster to use to the `Session` parameter. Use
    `New-BMSession` to create a session object.

    This function uses BuildMaster's native APIs.

    .EXAMPLE
    Get-BMEnvironment

    Demonstrates how to return a list of all BuildMaster active environments.

    .EXAMPLE
    Get-BMEnvironment -Name '*Dev*'

    Demonstrates how to use wildcards to search for active environments.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the environment to return. If one doesn't exist, you'll get an error. Wildcards supported when
        # passing an environment name. If no environments match the wildcard pattern, no error is returned.
        [Parameter(ValueFromPipeline)]
        [Alias('Name')]
        [Object] $Environment
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false

        $environments = $null

        $environmentName = $Environment | Get-BMObjectName -Strict -ErrorAction Ignore
        $searching = $environmentName -and [wildcardpattern]::ContainsWildcardCharacters($environmentName)

        Invoke-BMRestMethod -Session $Session -Name 'infrastructure/environments/list' |
            Where-Object {
                # Only return environments that match the user's search.
                if ($environmentName)
                {
                    return $_.name -like $environmentName
                }
                return $true
            } |
            ForEach-Object {
                # BuildMaster API doesn't always return these properties.
                $_ | Add-Member -MemberType NoteProperty -Name 'parentName' -Value '' -ErrorAction Ignore
                return $_
            } |
            Tee-Object -Variable 'environments' |
            Write-Output

        if ($Environment -and -not $environments -and -not $searching)
        {
            $msg = "Environment ""$($Environment | Get-BMObjectName)"" does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}