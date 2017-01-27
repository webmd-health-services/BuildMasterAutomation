

& (Join-Path -Path $PSScriptRoot -ChildPath '..\BuildMasterAutomation\Import-BuildMasterAutomation.ps1' -Resolve) -Verbose:$false

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'BuildMasterAutomationTest') -Force -Verbose:$false