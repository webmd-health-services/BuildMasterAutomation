<#
.SYNOPSIS
Gets the local machine ready for BuildMasterAutomation development.

.DESCRIPTION
The `init.ps1` script gets the local machine ready for BuildMasterAutomation development. It:

* installs BuildMaster

BuildMaster requires a SQL Server database. This script tries to use an existing database if possible. It uses the
`SqlServer` PowerShell module to enumerate local instances of SQL Server. It uses the first instance to be returned from
this set: the default instance, an `INEDO` instance name, or a `SQL2017` instance name. If none are installed, the
BuildMaster installer will install an `INEDO` SQL Server Express instance.

If BuildMaster is already installed, nothing happens.
#>
[CmdletBinding()]
param(
    [String] $SqlServerName
)

#Requires -RunAsAdministrator
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\Carbon.Windows.Installer') -Force -Verbose:$false
Import-Module -Name 'Microsoft.PowerShell.Archive' -Verbose:$false

# When updating the version, it's a good time to check if bugs in the API have been fixed. Search all the tests for
# "-Skip", remove the "-Skip" flag and run tests.
$version = '23.0.19'

Write-Information -Message "Testing BuildMaster ${version}."

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

$dbCredentials = 'Integrated Security=true;'
$runningUnderAppVeyor = (Test-Path -Path 'env:APPVEYOR')
if ($runningUnderAppVeyor)
{
    $dbCredentials = 'User ID=sa;Password=Password12!'
    $SqlServerName = ".\${env:SQL_INSTANCE_NAME}"
}
elseif (-not $SqlServerName)
{
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\SqlServer') -Force

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
        Where-Object { $_.Status -eq [Microsoft.SqlServer.Management.Smo.ServerStatus]::Online } |
        Sort-Object -Property 'Version' -Descending |
        Select-Object -First 1

    if (-not $sqlServer)
    {
        Write-Error -Message "Failed to find an installed, online SQL Server instance on the local computer."
        return
    }

    $SqlServerName = $sqlServer.name
}

Write-Information "Using SQL Server ${SqlServerName}."

# Free edition license
& $hubPath 'install' `
           "BuildMaster:$($version)" `
           --ConnectionString="Server=${SqlServerName}; ${dbCredentials}" `
           --LicenseKey=C2G2G010-GC100V-7M8X70-0QC1GFNK-H98U

Get-Service -Name 'Inedo*' | Start-Service
