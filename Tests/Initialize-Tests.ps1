
$importPath =
    Join-Path -Path $PSScriptRoot -ChildPath '..\BuildMasterAutomation\Import-BuildMasterAutomation.ps1' -Resolve
& $importPath -Verbose:$false

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'BuildMasterAutomationTest') -Force -Verbose:$false
