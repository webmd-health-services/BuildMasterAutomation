
$script:defaultRaftId = 1

enum BMRaftItemTypeCode
{
    Module = 3
    Script = 4
    DeploymentPlan = 6
    Pipeline = 8
}

Add-Type -AssemblyName 'System.Web'

$functionsDir = Join-Path -Path $PSScriptRoot -ChildPath 'Functions'
if( (Test-Path -Path $functionsDir -PathType Container) )
{
    foreach( $item in (Get-ChildItem -Path $functionsDir -Filter '*.ps1') )
    {
        . $item.FullName
    }
}
