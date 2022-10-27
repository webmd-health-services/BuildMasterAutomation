
$apiKey = 'HKgaAKWjjgB9YRrTbTpHzw=='

$bmNotInstalledMsg = 'It looks like BuildMaster isn''t installed. Please run init.ps1 to install and configure a local BuildMaster instance so we can run automated tests against it.'
$svcSharedConfigPath = Join-Path -Path $env:ProgramData -ChildPath 'Inedo\SharedConfig\BuildMaster.config' -Resolve
if( -not $svcSharedConfigPath )
{
    throw $bmNotInstalledMsg
}


$svcConfig = [xml](Get-Content -Path $svcSharedConfigPath -Raw)
if( -not $svcConfig )
{
    throw $bmNotInstalledMsg
}

$uri = $svcConfig.SelectSingleNode('/InedoAppConfig/WebServer').Attributes['Urls'].Value
$uri = $uri -replace '\*',$env:COMPUTERNAME
$connString = $svcConfig.SelectSingleNode('/InedoAppConfig/ConnectionString').InnerText

$conn = New-Object 'Data.SqlClient.SqlConnection'
$conn.ConnectionString = $connString
$conn.Open()

try
{
    $cmd = New-Object 'Data.SqlClient.SqlCommand'
    $cmd.Connection = $conn
    $cmd.CommandText = '[dbo].[ApiKeys_GetApiKeyByName]'
    $cmd.CommandType = [Data.CommandType]::StoredProcedure
    $cmd.Parameters.AddWithValue('@ApiKey_Text', $apiKey)

    $keyExists = $cmd.ExecuteScalar()
    if( -not $keyExists )
    {
        $apiKeyDescription = 'BuildMasterAutomation API Key'
        $apiKeyConfig = @'
<Inedo.BuildMaster.ApiKeys.ApiKey Assembly="BuildMaster">
    <Properties AllowNativeApi="True" CanViewInfrastructure="True" CanUpdateInfrastructure="True" AllowVariablesManagementApi="True" AllowReleaseAndPackageDeploymentApi="True" />
</Inedo.BuildMaster.ApiKeys.ApiKey>
'@
        $cmd.Dispose()

        $cmd = New-Object 'Data.SqlClient.SqlCommand'
        $cmd.CommandText = "[dbo].[ApiKeys_CreateOrUpdateApiKey]"
        $cmd.Connection = $conn
        $cmd.CommandType = [Data.CommandType]::StoredProcedure

        $parameters = @{
                            '@ApiKey_Text' = $apiKey;
                            '@ApiKey_Description' = $apiKeyDescription;
                            '@ApiKey_Configuration' = $apiKeyConfig
                        }
        foreach( $name in $parameters.Keys )
        {
            $value = $parameters[$name]
            if( -not $name.StartsWith( '@' ) )
            {
                $name = '@{0}' -f $name
            }
            Write-Verbose ('{0} = {1}' -f $name,$value)
            [void] $cmd.Parameters.AddWithValue( $name, $value )
        }
        $result = $cmd.ExecuteNonQuery();
    }
}
finally
{
    $conn.Close()
}

function New-BMTestApplication
{
    param(
        $Session,
        $CommandPath
    )

    $Name = Split-Path -Path $CommandPath -Leaf
    $Name = '{0}.{1}' -f $Name,[IO.Path]::GetRandomFileName()

    return New-BMApplication -Session $Session -Name $Name
}

$session = New-BMSession -Uri $uri -ApiKey $apiKey

function New-BMTestSession
{
    return $session
}

function GivenAnApplication
{
    param(
        [Parameter(Mandatory=$true)]
        $Name,

        [Switch]
        $ThatIsDisabled
    )

    $Name = Split-Path -Path $Name -Leaf
    $Name = '{0}.{1}' -f $Name,[IO.Path]::GetRandomFileName()

    $app = New-BMApplication -Session $session -Name $Name
    
    if( $ThatIsDisabled )
    {
        Disable-BMApplication -Session $session -ID $app.Application_Id |
            Out-String |
            Write-Debug
    }

    return $app
}

function GivenARelease
{
    param(
        [Parameter(Mandatory=$true)]
        $Named,
        [Parameter(Mandatory=$true)]
        $ForApplication,
        [Parameter(Mandatory=$true)]
        $WithNumber,
        [Parameter(Mandatory=$true)]
        $UsingPipeline
    )

    $Named = Split-Path -Path $Named -Leaf
    $Named = '{0}.{1}' -f $Named,[IO.Path]::GetRandomFileName()

    return New-BMRelease -Session $session -Application $ForApplication -Number $WithNumber -Name $Named -Pipeline $UsingPipeline
}

function GivenAPipeline
{
    param(
        [Parameter(Mandatory=$true)]
        $Named,

        $ForApplication
    )

    $Named = Split-Path -Path $Named -Leaf
    $Named = '{0}.{1}' -f $Named,[IO.Path]::GetRandomFileName()

    $appParam = @{ }
    if( $ForApplication )
    {
        $appParam['Application'] = $ForApplication
    }

    return New-BMPipeline -Session $session -Name $Named @appParam
}

function GivenAPackage
{
    [CmdletBinding(DefaultParameterSetName='WithAllTheTrimmings')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='WithAllTheTrimmings')]
        [string]
        $ForAnAppNamed,

        [Parameter(Mandatory=$true,ParameterSetName='WithAllTheTrimmings')]
        [string]
        $ForReleaseNumber,

        [Parameter(Mandatory=$true,ParameterSetName='ForARelease')]
        $ForRelease
    )

    if( $PSCmdlet.ParameterSetName -eq 'ForARelease' )
    {
        return New-BMPackage -Session $session -Release $ForRelease
    }

    $app = GivenAnApplication -Name $ForAnAppNamed
    $pipeline = GivenAPipeline -Named ('{0}.pipeline' -f $ForAnAppNamed)  -ForApplication $app
    $release = GivenARelease -Named ('{0}.release' -f $ForAnAppNamed) -ForApplication $app -WithNumber $ForReleaseNumber -UsingPipeline $pipeline
    return New-BMPackage -Session $session -Release $release
}

function ThenError
{
    param(
        [Parameter(Mandatory)]
        [string]$Matches
    )

    $Global:Error | Should -Match $Matches
}

function ThenNoErrorWritten
{
    $Global:Error | Should -BeNullOrEmpty
}

$BMTestSession = $session

Get-BMApplication -Session $session |
    ForEach-Object {
        Write-Debug -Message ('Deactivating and purging application {0,5} {1}.' -f $_.Application_Id,$_.Application_Name)
        Disable-BMApplication -Session $session -ID $_.Application_Id
        Invoke-BMNativeApiMethod -Session $session -Name 'Applications_PurgeApplicationData' -Method Post -Parameter @{ Application_Id  = $_.Application_Id }
    }

Invoke-BMNativeApiMethod -Session $session -Name 'Pipelines_GetPipelines' -Method Post -Parameter @{ } |
    ForEach-Object {
        Write-Debug -Message ('Deleting pipeline {0,5} {1}.' -f $_.Pipeline_Id,$_.Pipeline_Name)
        Invoke-BMNativeApiMethod -Session $session -Name 'Pipelines_DeletePipeline' -Method Post -Parameter @{ Pipeline_Id = $_.Pipeline_Id }
    }


Export-ModuleMember -Function '*' -Variable 'BMTestSession'