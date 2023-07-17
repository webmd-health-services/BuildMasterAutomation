<#
.SYNOPSIS
Gets the local machine ready for BuildMasterAutomation development.

.DESCRIPTION
The `init.ps1` script gets the local machine ready for BuildMasterAutomation development. It:

* installs BuildMaster

BuildMaster requires a SQL Server database. This script tries to use an existing database if possible. It uses the `SqlServer` PowerShell module to enumerate local instances of SQL Server. It uses the first instance to be returned from this set: the default instance, an `INEDO` instance name, or a `SQL2017` instance name. If none are installed, the BuildMaster installer will install an `INEDO` SQL Server Express instance.

If BuildMaster is already installed, nothing happens.
#>
[CmdletBinding()]
param(
)

#Requires -RunAsAdministrator
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

& {
    $VerbosePreference = 'SilentlyContinue'
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\Carbon.Windows.Installer') -Force
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\SqlServer') -Force
    Import-Module -Name 'Microsoft.PowerShell.Archive'
}



# When updating the version, it's a good time to check if bugs in the API have been fixed. Search all the tests for
# "-Skip", remove the "-Skip" flag and run tests.
$version = '22.0.12'



Write-Verbose -Message ('Testing BuildMaster {0}' -f $version)

$machineSqlPath = Join-Path -Path 'SQLSERVER:\SQL' -ChildPath ([Environment]::MachineName)
$sqlServer =
    Get-ChildItem -Path $machineSqlPath |
    Where-Object {
        if (Test-Path -Path 'env:SQL_INSTANCE_NAME')
        {
            return ($_.DisplayName -eq $env:SQL_INSTANCE_NAME)
        }
        return $true
    } |
    Where-Object { $_ | Get-Member -Name 'Status' } |
    Where-Object { $_.Status -eq [Microsoft.SqlServer.Management.Smo.ServerStatus]::Online }
    Sort-Object -Property 'Version' -Descending |
    Select-Object -First 1

if (-not $sqlServer)
{
    Write-Error -Message 'Failed to find an installed instance of SQL Server.'
    return
}

$outputPath = Join-Path -Path $PSScriptRoot -ChildPath '.output'
if (-not (Test-Path -Path $outputPath))
{
    New-Item -Path $outputPath -ItemType 'Directory' | Out-String | Write-Verbose
}

$hubPath = Join-Path -Path $outputPath -ChildPath 'InedoHub\hub.exe'
$hubUrl = 'https://proget.inedo.com/upack/Products/download/InedoReleases/DesktopHub?contentOnly=zip&latest'
if( -not (Test-Path -Path $hubPath) )
{
    $hubZipPath = Join-Path -Path $outputPath -ChildPath 'InedoHub.zip'
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest $hubUrl -OutFile $hubZipPath
    Expand-Archive -Path $hubZipPath -DestinationPath ($hubPath | Split-Path)
}

if( -not (Test-Path -Path $hubPath) )
{
    Write-Error -Message "Failed to download and extract Inedo Hub from ""$($hubUrl)""."
}

$runningUnderAppVeyor = (Test-Path -Path 'env:APPVEYOR')
$dbCredentials = 'Integrated Security=true;'
if( $runningUnderAppVeyor )
{
    $dbCredentials = 'User ID=sa;Password=Password12!'
}

# Free edition license
& $hubPath 'install' `
           "BuildMaster:$($version)" `
           --ConnectionString="Server=$($sqlServer.name); $($dbCredentials)" `
           --LicenseKey=C2G2G010-GC100V-7M8X70-0QC1GFNK-H98U

Get-Service -Name 'Inedo*' | Start-Service
