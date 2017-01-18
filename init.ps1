
Save-Module -Name 'Pester' -Path '.' 
Save-Module -Name 'Carbon' -Path '.'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon') -Force

$version = '5.6.4'
$bmInstallInfo = Get-ProgramInstallInfo -Name 'BuildMaster'
if( -not $bmInstallInfo )
{
    $installerPath = Join-Path -Path $env:TEMP -ChildPath ('BuildMasterInstaller-{0}.exe' -f $version)
    Invoke-WebRequest -Uri ('http://inedo.com/files/buildmaster/nosql/{0}.exe' -f $version) -OutFile $installerPath

    $appVeyorConnString = 'Server=(local)\SQL2016;Database=BuildMaster;User ID=sa;Password=Password12!'

    $connString = 'Server=.\InternalTools;Database=BuildMaster;Trusted_Connection=True'
    if( (Test-Path -Path 'env:APPVEYOR') )
    {
        $connString = $appVeyorConnString
    }

    & $installerPath /S /Edition=Express /ConnectionString=$connString /LogFile=buildmaster.install.log
    while( -not (Get-ProgramInstallInfo -Name 'BuildMaster') )
    {
        Start-Sleep -Seconds 1
    }
}
elseif( $bmInstallInfo.DisplayVersion -notmatch ('^{0}\b' -f [regex]::Escape($version)) )
{
    Write-Warning -Message ('You''ve got an old version of BuildMaster installed. You''re on version {0}, but we expected version {1}. Please *completely* uninstall version {0} using the Programs and Features control panel, then re-run this script.' -f $bmInstallInfo.DisplayVersion,$version)
}

