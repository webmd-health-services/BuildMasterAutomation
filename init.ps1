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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon') -Force -Verbose:$false

$version = '5.6.5'

$installerPath = Join-Path -Path $env:TEMP -ChildPath ('BuildMasterInstaller-{0}.exe' -f $version)
if( -not (Test-Path -Path $installerPath -PathType Leaf) )
{
    $uri = ('http://inedo.com/files/buildmaster/nosql/{0}.exe' -f $version)
    Write-Verbose -Message ('Downloading {0}' -f $uri)
    Invoke-WebRequest -Uri $uri -OutFile $installerPath
}

$bmInstallInfo = Get-ProgramInstallInfo -Name 'BuildMaster'
if( -not $bmInstallInfo )
{
    $appVeyorConnString = 'Server=(local)\SQL2016;Database=BuildMaster;User ID=sa;Password=Password12!'

    $connString = 'Server=.\InternalTools;Database=BuildMaster;Trusted_Connection=True'
    if( (Test-Path -Path 'env:APPVEYOR') )
    {
        $connString = $appVeyorConnString
    }

    Write-Verbose -Message ('Running BuildMaster installer {0}.' -f $installerPath)
    $logPath = Join-Path -Path $PSScriptRoot -ChildPath 'buildmaster.install.log'
    $process = Start-Process -FilePath $installerPath -ArgumentList '/S','/Edition=Express',('/ConnectionString={0}' -f $connString),('/LogFile={0}' -f $logPath) -Wait -PassThru
    $process.WaitForExit()

    if( -not (Get-ProgramInstallInfo -Name 'BuildMaster') )
    {
        if( (Test-Path -Path 'env:APPVEYOR') )
        {
            Get-Content -Path $logPath | Write-Output
        }
        Write-Error -Message ('It looks like BuildMaster {0} didn''t install. The install log might have more information: {1}' -f $version,$logPath)
    }
}
elseif( $bmInstallInfo.DisplayVersion -notmatch ('^{0}\b' -f [regex]::Escape($version)) )
{
    Write-Warning -Message ('You''ve got an old version of BuildMaster installed. You''re on version {0}, but we expected version {1}. Please *completely* uninstall version {0} using the Programs and Features control panel, then re-run this script.' -f $bmInstallInfo.DisplayVersion,$version)
}

