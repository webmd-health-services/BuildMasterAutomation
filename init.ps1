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
)

#Requires -RunAsAdministrator
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& {
    $VerbosePreference = 'SilentlyContinue'
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\Carbon') -Force
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\SqlServer') -Force
}

$runningUnderAppVeyor = (Test-Path -Path 'env:APPVEYOR')

$version = '6.1.8'
$sqlServer = $null
$installerPath = 'SQL'
$installerUri = 'sql'
$dbParam = '/InstallSqlExpress'

foreach( $item in (Get-ChildItem -Path ('SQLSERVER:\SQL\{0}' -f [Environment]::MachineName)) )
{
    if( $item.Status -ne [Microsoft.SqlServer.Management.Smo.ServerStatus]::Online )
    {
        Write-Verbose -Message ('Skipping SQL Server instance "{0}": "{1}".' -f $item.Name,$item.Status)
        continue
    }

    $item | Format-List | Out-String | Write-Verbose

    if( -not $item.InstanceName -or $item.InstanceName -in @( 'Inedo', 'SQL2016' ) )
    {
        $installerPath = 'NO{0}' -f $installerPath
        $installerUri = 'no{0}' -f $installerUri
        $sqlServer = $item
        $credentials = 'Integrated Security=true;'
        if( $runningUnderAppVeyor )
        {
            $credentials = 'User ID=sa;Password=Password12!'
        }
        $dbParam = '"/ConnectionString=Server={0};Database=BuildMaster;{1}"' -f $sqlServer.Name,$credentials
        break
    }
}

$installerPath = Join-Path -Path $PSScriptRoot -ChildPath ('.output\BuildMasterInstaller{0}-{1}.exe' -f $installerPath,$version)
$installerUri = 'http://inedo.com/files/buildmaster/{0}/{1}.exe' -f $installerUri,$version

if( -not (Test-Path -Path $installerPath -PathType Leaf) )
{
    Write-Verbose -Message ('Downloading {0}' -f $installerUri)
    Invoke-WebRequest -Uri $installerUri -OutFile $installerPath
}

$bmInstallInfo = Get-ProgramInstallInfo -Name 'BuildMaster'
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
    $argumentList = '/S','/Edition=Express',$dbParam,('"/LogFile={0}"' -f $logPath)
    Write-Verbose ('{0} {1}' -f $installerPath,($argumentList -join ' '))
    $process = Start-Process -FilePath $installerPath `
                             -ArgumentList $argumentList `
                             -Wait `
                             -PassThru `
                             -RedirectStandardError $stdErrLogPath `
                             -RedirectStandardOutput $stdOutLogPath
    $process.WaitForExit()

    Write-Verbose -Message ('{0} exited with code {1}' -f $installerFileName,$process.ExitCode)

    if( -not (Get-ProgramInstallInfo -Name 'BuildMaster') )
    {
        if( $runningUnderAppVeyor )
        {
            Get-ChildItem -Path $logRoot |
                ForEach-Object {
                    $_
                    $_ | Get-Content
                }
        }
        Write-Error -Message ('It looks like BuildMaster {0} didn''t install. The install log might have more information: {1}' -f $version,$logPath)
    }
}
elseif( $bmInstallInfo.DisplayVersion -notmatch ('^{0}\b' -f [regex]::Escape($version)) )
{
    Write-Warning -Message ('You''ve got an old version of BuildMaster installed. You''re on version {0}, but we expected version {1}. Please *completely* uninstall version {0} using the Programs and Features control panel, then re-run this script.' -f $bmInstallInfo.DisplayVersion,$version)
}

