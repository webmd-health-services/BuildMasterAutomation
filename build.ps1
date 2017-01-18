[CmdletBinding()]
param(
)

& (Join-Path -Path $PSScriptRoot -ChildPath 'init.ps1' -Resolve)

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Pester' -Resolve) -Force

$outputdir = Join-Path -Path $PSScriptRoot -ChildPath '.output'

New-Item -Path $outputdir -ItemType 'Directory' -ErrorAction Ignore
Get-ChildItem -Path $outputdir | Remove-Item -Recurse -Force

$result = Invoke-Pester -Script (Join-Path -Path $PSScriptRoot -ChildPath 'Tests\*.Tests.ps1') `
                        -OutputFile (Join-Path -Path $outputdir -ChildPath 'pester.xml') `
                        -OutputFormat NUnitXml `
                        -PassThru

exit $result.FailedCount