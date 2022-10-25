
function New-BMEnvironment
{
    <#
    .SYNOPSIS
    Creates a new environment in a BuildMaster instance.

    .DESCRIPTION
    The `New-BMEnvironment` creates a new environment in BuildMaster. Pass the name of the environment to the `Name`
    parameter. Names may only contain letters, numbers, periods, underscores, or dashes and may not end with an
    underscore or dash.  Every environment must have a unique name. If you create a environment with a duplicate name,
    the BuildMaster error returns an error.

    You can set an new environment's parent environment with the `ParentName` parameter. You can create an inactive
    environment by using the `Inactive` switch.

    To return the environment, even if it already exists, use the `PassThru` switch.

    This function uses BuildMaster's infrastructure management API.

    .EXAMPLE
    New-BMEnvironment -Session $session -Name 'DevNew'

    Demonstrates how to create a new environment.

    .EXAMPLE
    New-BMEnvironment -Session $session -Name 'DevNew' -ErrorAction Ignore -PassThru

    Demonstrates how to ignore if an environment already exists and to return an enviornment object representing the
    new or already existing environment.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the environment to create. Must contain only letters, numbers, underscores, or dashes. Must begin
        # with a letter. Must not end with an underscore or dash. Must be between 1 and 50 characters long.
        [Parameter(Mandatory)]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9_-]*(?<![_-])$')]
        [ValidateLength(1,50)]
        [String] $Name,

        # The name of this environment's parent environemnt.
        [String] $ParentName,

        # By default, new environments are active. If you want the environment to be inactive, use this switch.
        [switch] $Inactive,

        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameter = @{
                    name = $Name;
                    parentName = $ParentName;
                    active = (-not $Inactive);
                 }
    $encodedName = [Uri]::EscapeDataString($Name)
    Invoke-BMRestMethod -Session $Session `
                        -Name ('infrastructure/environments/create/{0}' -f $encodedName) `
                        -Method Post `
                        -Parameter $parameter `
                        -AsJson
    if ($PassThru)
    {
        return Get-BMEnvironment -Session $Session -Environment ([pscustomobject]@{ 'Name' = $Name})
    }
}