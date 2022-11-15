
function Get-BMApplication
{
    <#
    .SYNOPSIS
    Gets BuildMaster applications.

    .DESCRIPTION
    The `Get-BMApplication` function gets all active applications from an instance of BuildMaster. Use the `Force`
    switch to include inactive applications.

    To get a specific application, pass its id, name (wildcards supported), or object to the `Application` parameter.
    The function writes an error if the application does not exist.

    .EXAMPLE
    Get-BMApplication -Session $session

    Demonstrates how to get all active BuildMaster applications

    .EXAMPLE
    Get-BMApplication -Session $session -Force

    Demonstrates how to get all active *and* inactive/disabled BuildMaster applications.

    .EXAMPLE
    Get-BMApplication -Session $session -Name 'MyApplication'

    Demonstrates how to get a specific application.
    #>
    [CmdletBinding(DefaultParameterSetName='AllApplications')]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The application to get. Pass an application id, name (wildcards supported), or object.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='SpecificApplication')]
        [Alias('Name')]
        [Object] $Application,

        # Force `Get-BMApplication` to return inactive/disabled applications.
        [Parameter(ParameterSetName='AllApplications')]
        [switch] $Force
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Invoke-BMNativeApiMethod uses POST, but we're reading data, so always make the request.
        $WhatIfPreference = $false

        $searching = $Application -and `
                     ($Application | Test-BMName) -and `
                     [wildcardpattern]::ContainsWildcardCharacters($Application)

        $parameters =
            @{
                Application_Count = 0;
                IncludeInactive_Indicator = ($Force.IsPresent -or $PSCmdlet.ParameterSetName -eq 'SpecificApplication');
            } |
            Add-BMObjectParameter -Name 'Application' -Value $Application -ForNativeApi -PassThru

        $endpoint = 'Applications_GetApplication'
        if ($PSCmdlet.ParameterSetName -eq 'AllApplications' -or $searching)
        {
            $endpoint = 'Applications_GetApplications'
        }
        $apps = @()
        Invoke-BMNativeApiMethod -Session $Session -Name $endpoint -Parameter $parameters -Method Post |
            ForEach-Object {
                if ($_ | Get-Member -Name 'Applications_Extended')
                {
                    return $_.Applications_Extended
                }
                return $_
            } |
            Where-Object {
                if ($searching)
                {
                    return $_.Application_Name -like $Application
                }
                return $true
            } |
            Tee-Object -Variable 'apps' |
            Write-Output

        if ($Application -and -not $apps -and -not $searching)
        {
            $msg = "Application ""$($Application | Get-BMObjectName -ObjectTypeName 'Application')"" does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}
