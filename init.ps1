[CmdletBinding()]
param(
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

foreach( $moduleName in @( 'Pester', 'Carbon' ) )
{
    if( (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath $moduleName) -PathType Container) )
    {
        break
    }

    Save-Module -Name $moduleName -Path '.' 
}

if (Get-Module -Name 'Carbon') {Remove-Module -Name 'Carbon'}
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon') -Force -Verbose:$false

$runningUnderAppVeyor = (Test-Path -Path 'env:APPVEYOR')

$version = '5.6.5'

$installerPath = Join-Path -Path $env:TEMP -ChildPath ('BuildMasterInstaller-SQL-{0}.exe' -f $version)
if( -not (Test-Path -Path $installerPath -PathType Leaf) )
{
    $uri = ('http://inedo.com/files/buildmaster/sql/{0}.exe' -f $version)
    Write-Verbose -Message ('Downloading {0}' -f $uri)
    Invoke-WebRequest -Uri $uri -OutFile $installerPath
}

$bmInstallInfo = Get-ProgramInstallInfo -Name 'BuildMaster'
if( -not $bmInstallInfo )
{
    $bmConnectionString = '/ConnectionString="Data Source=localhost\BuildMaster; Initial Catalog=BuildMaster; Integrated Security=True;"'
    $dbParam = '/InstallSqlExpress'
    $pgInstallInfo = Get-ProgramInstallInfo -Name 'ProGet'
    if ($pgInstallInfo) {
        Write-Verbose -Message 'ProGet is installed. BuildMaster will join existing SQL Server instance..'
        $pgConfigLocation = Join-Path -Path (Get-ItemProperty -Path 'HKLM:\Software\Inedo\ProGet').ServicePath -ChildPath 'ProGet.Service.exe.config'
    
        $xml = [xml](Get-Content -Path $pgConfigLocation) 
        $pgDbConfigSetting = $xml.SelectSingleNode("//add[@key = 'InedoLib.DbConnectionString']")
        $pgConnectionString = $pgDbConfigSetting.Value.Substring(0,$pgDbConfigSetting.Value.IndexOf(';'))
        $bmConnectionString = ('/ConnectionString="{0};Initial Catalog=BuildMaster; Integrated Security=True;"' -f $pgConnectionString)
        $dbParam = '/InstallSqlExpress=False'
    }
    
    # Under AppVeyor, use the pre-installed database.
    # Otherwise, install a SQL Express BuildMaster instance.
    if( $runningUnderAppVeyor )
    {
        $dbParam = '"/ConnectionString=Server=(local)\SQL2016;Database=BuildMaster;User ID=sa;Password=Password12!"'
    }

    $outputRoot = Join-Path -Path $PSScriptRoot -ChildPath '.output'
    New-Item -Path $outputRoot -ItemType 'Directory' -ErrorAction Ignore

    $logRoot = Join-Path -Path $outputRoot -ChildPath 'logs'
    New-Item -Path $logRoot -ItemType 'Directory' -ErrorAction Ignore

    Write-Verbose -Message ('Running BuildMaster installer {0}.' -f $installerPath)
    $logPath = Join-Path -Path $logRoot -ChildPath 'buildmaster.install.log'
    $installerFileName = $installerPath | Split-Path -Leaf
    $stdOutLogPath = Join-Path -Path $logRoot -ChildPath ('{0}.stdout.log' -f $installerFileName)
    $stdErrLogPath = Join-Path -Path $logRoot -ChildPath ('{0}.stderr.log' -f $installerFileName)
    $process = Start-Process -FilePath $installerPath `
                             -ArgumentList '/S','/Edition=Express',$bmConnectionString,$dbParam,('"/LogFile={0}"' -f $logPath),'/Port=81' `
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

