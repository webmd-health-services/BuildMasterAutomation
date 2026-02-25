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
    [String] $SqlServerName,

    [Parameter(Mandatory)]
    [String] $Version
)

#Requires -RunAsAdministrator
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

Import-Module -Name 'Microsoft.PowerShell.Archive' -Verbose:$false

$psModulesDirPath = Join-Path -Path $PSScriptRoot -ChildPath 'PSModules' -Resolve
Import-Module -Name (Join-Path -Path $psModulesDirPath -ChildPath 'Yodel' -Resolve) `
              -Function @('Connect-YDatabase', 'Invoke-YMsSqlCommand') `
              -Verbose:$false

Write-Information -Message "Installing BuildMaster ${Version}."

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
    Import-Module -Name (Join-Path -Path $psModulesDirPath -ChildPath 'SqlServer') -Force -Verbose:$false

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
$licenseKey = 'C2G2G010-GC100V-7M8X70-0QC1GFNK-H98U'
$connString = "Server=${SqlServerName}; ${dbCredentials}"
Write-Verbose "Connection String  ${connString}"

& $hubPath 'install' "BuildMaster:${Version}" --ConnectionString="${connString}" --LicenseKey="${licenseKey}"

$bmSvcs = Get-Service -Name 'INEDOBM*'

$bmSvcs | Start-Service

$bmReconfigured = $false

$conn = Connect-YDatabase -Provider ([Data.SqlClient.SqlClientFactory]::Instance) `
                          -ConnectionString "${connString}; Database=BuildMaster"

$query = 'select name from sys.procedures where name=''ApiKeys_GetApiKeyByName'''
while ($true)
{
    Write-Information 'Waiting for BuildMaster database.'
    try
    {
        if (Invoke-YMsSqlCommand -Connection $conn -Text $query -AsScalar)
        {
            break
        }
    }
    catch
    {
        Write-Warning $_
    }
    Start-Sleep -Seconds 1
}

try
{
    $apiKey = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath '.apikey') -ReadCount 1

    $keyExists = Invoke-YMsSqlCommand -Connection $conn `
                                      -Text '[dbo].[ApiKeys_GetApiKeyByName]' `
                                      -Type StoredProcedure `
                                      -AsScalar `
                                      -Parameter @{ '@ApiKey_Text' = $apiKey }
    if (-not $keyExists)
    {
        $apiKeyDescription = 'BuildMasterAutomation API Key'
        $apiKeyConfig = @'
<Inedo.BuildMaster.ApiKeys.ApiKey Assembly="BuildMaster">
    <Properties AllowNativeApi="True" CanViewInfrastructure="True" CanUpdateInfrastructure="True" AllowVariablesManagementApi="True" AllowReleaseAndPackageDeploymentApi="True" />
</Inedo.BuildMaster.ApiKeys.ApiKey>
'@

        Write-Information 'Inserting test API key into BuildMaster database.'
        Invoke-YMsSqlCommand -Connection $conn `
                             -Text '[dbo].[ApiKeys_CreateOrUpdateApiKey]' `
                             -Type StoredProcedure `
                             -Parameter @{
                                    '@ApiKey_Text' = $apiKey;
                                    '@ApiKey_Description' = $apiKeyDescription;
                                    '@ApiKey_Configuration' = $apiKeyConfig
                                } `
                             -NonQuery | Out-Null

        $bmReconfigured = $true
    }

    $currentLicense = Invoke-YMsSqlCommand -Connection $conn `
                                           -Text '[dbo].[Configuration_GetValue]' `
                                           -Type StoredProcedure `
                                           -Parameter @{ '@Key_Name' = 'Licensing.Key' }
    if (-not $currentLicense)
    {
        Write-Information 'Adding license key to BuildMaster database.'
        Invoke-YMsSqlCommand -Connection $conn `
                             -Text '[dbo].[Configuration_SetValue]' `
                             -Type StoredProcedure `
                             -Parameter @{
                                    '@Key_Name' = 'Licensing.Key'
                                    '@Value_Text' = $licenseKey
                                } `
                             -NonQuery | Out-Null

        $bmReconfigured = $true
    }
}
finally
{
    $conn.Close()
}

if ($bmReconfigured)
{
    Write-Information 'Restarting BuildMaster services.'
    $bmSvcs | Restart-Service
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'BuildMasterAutomation' -Resolve) -Force -Verbose:$false

$session = New-BMSession -Url "http://$([Environment]::MachineName):8622/" -ApiKey $apiKey

# Before BuildMaster is activated, the APIs return the licensing page HTML.
do
{
    Write-Information 'Waiting for BuildMaster activation.'
    try
    {
        $result = Invoke-BMRestMethod -Session $session -Name 'infrastructure/servers/list'
        if ($result -isnot [String])
        {
            break
        }
        $result | Out-String | Write-Verbose
    }
    catch
    {
        Write-Warning $_
    }

    Start-Sleep -Seconds 1
}
while ($true)
