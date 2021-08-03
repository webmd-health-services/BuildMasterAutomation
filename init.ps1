<#
.SYNOPSIS
Gets the local machine ready for BuildMasterAutomation development.

.DESCRIPTION
The `init.ps1` script gets the local machine ready for BuildMasterAutomation development. It:

* installs BuildMaster

BuildMaster requires a SQL Server database. This script tries to use an existing database if possible. It uses the `SqlServer` PowerShell module to enumerate local instances of SQL Server. It uses the first instance to be returned from this set: the default instance, an `INEDO` instance name, or a `SQL2016` instance name. If none are installed, the BuildMaster installer will install an `INEDO` SQL Server Express instance.

If BuildMaster is already installed, nothing happens.
#>
[CmdletBinding()]
param(
    [String] $SqlServerName
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'
$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue
$InformationPreference = [Management.Automation.ActionPreference]::Continue

$runningUnderAppVeyor = (Test-Path -Path 'env:APPVEYOR')

$version = '6.1.28'
Write-Verbose -Message ('Testing BuildMaster {0}' -f $version)
$credentials = 'Integrated Security=True'
if( -not $SqlServerName )
{
    if( $runningUnderAppVeyor )
    {
        $SqlServerName = '.\SQL2016'
        $credentials = 'User ID=sa;Password=Password12!'
    }
    else
    {
        $SqlServerName = '.'
    }
}

$connString = "Server=$($SqlServerName);Database=BuildMaster;$($credentials)"

# Always install the latest Hub.
$hubDirPath = Join-Path -Path $PSScriptRoot -ChildPath '.output\InedoHub'
$hubPath = Join-Path -Path $hubDirPath -ChildPath 'hub.exe'
if( (Test-Path -Path $hubDirPath) )
{
    Remove-Item -Path $hubDirPath -Recurse -Force -ErrorAction Stop
}
New-Item -Path $hubDirPath -ItemType 'Directory' -Force | Out-Null

$hubZipPath = Join-Path -Path ($hubDirPath | Split-Path) -ChildPath 'InedoDesktopHub.zip'
$hubZipUrl = 'https://proget.inedo.com/upack/Products/download/InedoReleases/DesktopHub?contentOnly=zip&latest'

Invoke-WebRequest -Uri $hubZipUrl -OutFile $hubZipPath
Expand-Archive -Path $hubZipPath -DestinationPath $hubDirPath

$installedApps = "`n" | & $hubPath 'list'
if( ($installedApps | Select-String "BuildMaster $($version)" -SimpleMatch) )
{
    Write-Information "BuildMaster already installed.`n$($installedApps)"
    exit 0
}

& $hubPath 'install' "BuildMaster:$($version)" --ConnectionString=$connString

if( (Get-Service -Name 'INEDOBM*' | Measure-Object).Count -ne 2 )
{
    Write-Error -Message 'It looks like BuildMaster wasn''t installed. Didn''t find the two BuildMaster services.'
    exit 1
}

exit 0