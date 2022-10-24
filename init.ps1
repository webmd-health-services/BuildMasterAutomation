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

$InformationPreference = 'Continue'

& {
    $VerbosePreference = 'SilentlyContinue'
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\Carbon.Windows.Installer') -Force
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\SqlServer') -Force
}

$runningUnderAppVeyor = (Test-Path -Path 'env:APPVEYOR')


# When updating the version, it's a good time to check if bugs in the API have been fixed. Do the following:
#
# * Remove the skipped tests in the Get-BMVariable and Remove-BMVariable tests.
$version = '6.2.33'



Write-Verbose -Message ('Testing BuildMaster {0}' -f $version)
$sqlServer = $null
$installerPath = 'SQL'
$installerUri = 'sql'
$dbParam = '/InstallSqlExpress'

Get-ChildItem -Path 'env:' | Format-Table

$machineSqlPath = Join-Path -Path 'SQLSERVER:\SQL' -ChildPath ([Environment]::MachineName)
$sqlServer =
    Get-ChildItem -Path $machineSqlPath |
    Where-Object {
        if (Test-Path -Path 'env:SQL_INSTANCE_NAME')
        {
            return ($_.DisplayName -eq $env:SQL_INSTANCE_NAME)
        }
    } |
    Where-Object { $_ | Get-Member -Name 'Status' } |
    Where-Object { $_.Status -eq [Microsoft.SqlServer.Management.Smo.ServerStatus]::Online }
    Sort-Object -Property 'Version' -Descending |
    Select-Object -First 1

if ($sqlServer)
{
    $sqlServer | Format-Table -Auto

    $installerPath = 'NO{0}' -f $installerPath
    $installerUri = 'no{0}' -f $installerUri
    $credentials = 'Integrated Security=true;'
    if( $runningUnderAppVeyor )
    {
        $credentials = 'User ID=sa;Password=Password12!'
    }
    $dbParam = '"/ConnectionString=Server={0};Database=BuildMaster;{1}"' -f $sqlServer.Name,$credentials
}


$installerPath = Join-Path -Path $PSScriptRoot -ChildPath ('.output\BuildMasterInstaller{0}-{1}.exe' -f $installerPath,$version)
$installerUri = 'https://my.inedo.com/services/legacy/downloads/buildmaster/{0}/{1}.exe' -f $installerUri,$version

if( -not (Test-Path -Path $installerPath -PathType Leaf) )
{
    Write-Verbose -Message ('Downloading {0}' -f $installerUri)
    Invoke-WebRequest -Uri $installerUri -OutFile $installerPath
}

$bmInstallInfo = Get-CInstalledProgram -Name 'BuildMaster' -ErrorAction Ignore
if( -not $bmInstallInfo )
{
    $outputRoot = Join-Path -Path $PSScriptRoot -ChildPath '.output'
    New-Item -Path $outputRoot -ItemType 'Directory' -ErrorAction Ignore

    $logRoot = Join-Path -Path $outputRoot -ChildPath 'logs'
    New-Item -Path $logRoot -ItemType 'Directory' -ErrorAction Ignore

    Write-Verbose -Message ('Running BuildMaster installer {0}.' -f $installerPath)
    $logPath = Join-Path -Path $logRoot -ChildPath 'buildmaster.install.log'
    $installerFileName = $installerPath | Split-Path -Leaf
    $stdOutLogPath = Join-Path -Path $logRoot -ChildPath ('{0}.stdout.log' -f $installerFileName)
    $stdErrLogPath = Join-Path -Path $logRoot -ChildPath ('{0}.stderr.log' -f $installerFileName)
    $argumentList = '/S','/Edition=LicenseKey','/LicenseKey=C2G2G010-GC100V-7M8X70-0QC1GFNK-H98U',$dbParam,('"/LogFile={0}"' -f $logPath)
    Write-Verbose ('{0} {1}' -f $installerPath,($argumentList -join ' '))
    $process = Start-Process -FilePath $installerPath `
                             -ArgumentList $argumentList `
                             -Wait `
                             -PassThru `
                             -RedirectStandardError $stdErrLogPath `
                             -RedirectStandardOutput $stdOutLogPath
    $process.WaitForExit()

    Write-Verbose -Message ('{0} exited with code {1}' -f $installerFileName,$process.ExitCode)

    if( -not (Get-CInstalledProgram -Name 'BuildMaster' -ErrorAction Continue) )
    {
        $logPath, $stdOutLogPath, $stdErrLogPath |
            Where-Object { Test-Path -Path $_ } |
            ForEach-Object {
                $filePath = $_
                Write-Information "$($filePath):"
                Get-Content -Path $filePath | ForEach-Object { Write-Information $_ }
                Write-Information ""
            }
        Write-Error 'BuildMaster installer failed.'
    }
}
elseif( $bmInstallInfo.DisplayVersion -notmatch ('^{0}\b' -f [regex]::Escape($version)) )
{
    Write-Warning -Message ('You''ve got an old version of BuildMaster installed. You''re on version {0}, but we expected version {1}. Please *completely* uninstall version {0} using the Programs and Features control panel, then re-run this script.' -f $bmInstallInfo.DisplayVersion,$version)
}

