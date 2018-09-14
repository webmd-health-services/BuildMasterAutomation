[CmdletBinding()]
param(
)

if( (Get-Module -Name 'BuildMasterAutomation') )
{
    Remove-Module -Name 'BuildMasterAutomation' -Force -WhatIf:$false
}

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'BuildMasterAutomation.psd1' -Resolve)
