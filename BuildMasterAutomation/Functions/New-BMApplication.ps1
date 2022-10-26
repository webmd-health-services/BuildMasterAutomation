
function New-BMApplication
{
    <#
    .SYNOPSIS
    Creates an application in BuildMaster.

    .DESCRIPTION
    The `New-BMApplication` function creates an application in BuildMaster. This function uses the native BuildMaster
    API. Only a name is required to create an application. The name must be unique and not in use.

    These parameters are also available:

    * `ReleaseNumberScheme`: sets the release number scheme to use when you create a new release for the application
    Options are `MajorMinorRevision`, `MajorMinor`, or `DateBased`.
    * `BuildNumberScheme`: sets the build number scheme to use when creating new builds for an application.
    Options are `Unique`, `Sequential`, `DateBased`.
    * `Raft` to set the raft in which the application's scripts, pipelines, etc. should be saved.

    .EXAMPLE
    New-BMApplication -Session $session -Name 'MyNewApplication'

    Demonstrates the simplest way to create an application. In this example, a `MyNewApplication` application will be
    created and all its fields set to BuildMaster's default values.

    .EXAMPLE
    New-BMApplication -Session $session -Name 'MyNewApplication' -ReleaseNumberSchemeName MajorMinor -BuildNumberSchemeName Sequential

    This example demonstrates all the fields you can set when creating a new application. In this example, the new
    application will be called `MyNewApplication`, its release number scheme will be `MajorMinor`, and its build number
    schema will be `Sequential`.
    #>
    [CmdletBinding()]
    param(
        # A session object that represents the BuildMaster instance to use. Use the `New-BMSession` function to create
        # session objects.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the application.
        [Parameter(Mandatory)]
        [String] $Name,

        # The name of the release number scheme. Should be one of:
        #
        # * `MajorMinorRevision`
        # * `MajorMinor`
        # * `DateBased`
        [ValidateSet('MajorMinorRevision', 'MajorMinor', 'DateBased')]
        [String] $ReleaseNumberSchemeName,

        # The name of the build number scheme. Should be one of:
        #
        # * `Unique`
        # * `Sequential`
        # * `DateTimeBased`
        [ValidateSet('Unique', 'Sequential', 'DateTimeBased')]
        [String] $BuildNumberSchemeName,

        # The application group to assign. By default, the application will be ungrouped. Pass an application group id
        # or object.
        [Alias('ApplicationGroupID')]
        [Object] $ApplicationGroup,

        # The raft where the application's raft items will be stored. Pass a raft id, name, or raft object.
        [Object] $Raft
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $application = $Name | Get-BMApplication -Session $Session -ErrorAction Ignore
    if ($application)
    {
        Write-Error -Message "Application ""$($Name)"" already exists." -ErrorAction $ErrorActionPreference
        return
    }

    # We use the value in $PSBoundParameters because it is $null if not provided by the user. PowerShell sets a
    # not-provided [String] argument value to empty string. We need $null so `Add-BMParameter` knows the parameter was
    # not provided and won't add it to the parameter hashtable.
    $parameters =
        @{} |
        Add-BMParameter -Name 'Application_Name' -Value $Name -PassThru |
        Add-BMObjectParameter -Name 'ApplicationGroup' -Value $ApplicationGroup -ForNativeApi -PassThru |
        Add-BMParameter -Name 'ReleaseNumber_Scheme_Name' `
                        -Value $PSBoundParameters['ReleaseNumberSchemeName'] `
                        -PassThru |
        Add-BMParameter -Name 'BuildNumber_Scheme_Name' -Value $PSBoundParameters['BuildNumberSchemeName'] -PassThru

    $appID = Invoke-BMNativeApiMethod -Session $Session `
                                      -Name 'Applications_CreateApplication' `
                                      -Parameter $parameters `
                                      -Method Post
    if( -not $appID )
    {
        return
    }

    if ($Raft)
    {
        $editArgs =
            @{} |
            Add-BMParameter -Name 'Application_Id' -Value $appID -PassThru |
            Add-BMParameter -Name 'Application_Name' -Value $Name -PassThru |
            Add-BMObjectParameter -Name 'Raft' -Value $Raft -AsName -ForNativeApi -PassThru
        Invoke-BMNativeApiMethod -Session $Session `
                                 -Name 'Applications_EditApplication' `
                                 -Parameter $editArgs `
                                 -Method Post
    }

    Invoke-BMNativeApiMethod -Session $Session `
                             -Name 'Applications_GetApplication' `
                             -Parameter @{ 'Application_Id' = $appID } `
                             -Method Post |
        Select-Object -ExpandProperty 'Applications_Extended'
}