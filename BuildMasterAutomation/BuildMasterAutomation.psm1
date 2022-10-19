
$script:defaultRaftId = 1

enum BMRaftItemTypeCode
{
    Module = 3
    Script = 4
    DeploymentPlan = 6
    Pipeline = 8
}

Add-Type -AssemblyName 'System.Web'

$script:warnings = @{}

function Write-WarningOnce
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0, ParameterSetName='Message', ValueFromPipeline)]
        [String] $Message
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if( $script:warnings[$Message] )
        {
            return
        }

        Write-Warning -Message $Message
        $script:warnings[$Message] = $true
    }
}


$functionsDir = Join-Path -Path $PSScriptRoot -ChildPath 'Functions'
if( (Test-Path -Path $functionsDir -PathType Container) )
{
    foreach( $item in (Get-ChildItem -Path $functionsDir -Filter '*.ps1') )
    {
        . $item.FullName
    }
}
