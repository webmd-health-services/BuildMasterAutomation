[CmdletBinding()]
param(
    [switch] $Force
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'
$InformationPreference = 'Continue'

if (Get-Process -Name 'InedoHub' -ErrorAction Ignore)
{
    if (-not $Force)
    {
        $msg = 'Failed to uninstall BuildMaster because the InedoHub is running. Either quit the Inedo Hub or use ' +
               '-Force swich to forcefully terminate it.'
        Write-Error -Message $msg
        exit 1
    }

    Get-Process -Name 'InedoHub' | Stop-Process -Force
invoke-}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\Carbon' -Resolve)

foreach ($service in (Get-Service -Name 'INEDOBM*'))
{
    Write-Information "Uninstalling $($service.Name) service."
    Uninstall-CService -Name $service.Name
}


$programDataPath = [Environment]::GetFolderPath('CommonApplicationData')
$configDirPath = Join-Path -Path $programDataPath -ChildPath 'Inedo\SharedConfig'

# Make sure we can recover any config files.
foreach ($configFile in (Get-ChildItem -Path $configDirPath -File -ErrorAction Ignore))
{
    $configFilePath = $configFile.FullName
    $shell = New-Object -ComObject "Shell.Application"
    $item = $shell.Namespace(0).ParseName($configFilePath)
    Write-Information "Moving config file ""${configFilePath}"" to the Recycle Bin."
    $item.InvokeVerb("delete")
}

$continueMsg = "Inedo shared config files exist in ""${configDirPath}"". Are you sure you want to remove the " +
               """$($configDirPath | Split-Path -Parent)"" parent directory and all other BuildMaster files?"
if ((Test-Path -Path (Join-Path -Path $configDirPath -ChildPath '*.config')) -and `
    -not $Force -and `
    -not $PSCmdlet.ShouldContinue($continueMsg, 'Confirm Removal of Inedo Config Files'))
{
    exit 1
}

$dirsToDelete = @(
    (Join-Path -Path $programDataPath -ChildPath 'Inedo'),
    (Join-Path -Path $programDataPath -ChildPath 'BuildMaster'),
    (Join-Path -Path $programDataPath -ChildPath 'Romp'),
    (Join-Path -Path $programDataPath -ChildPath 'upack'),
    (Join-Path -Path ([Environment]::GetFolderPath('ProgramFiles')) -ChildPath 'BuildMaster')
)

foreach ($dirToDelete in $dirsToDelete)
{
    if (-not (Test-Path -Path $dirToDelete))
    {
        continue
    }

    Write-Information "Deleting directory ""${dirToDelete}""."
    Remove-Item -Path $dirToDelete -Recurse -Force
}
