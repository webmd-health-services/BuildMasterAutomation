
$apiKey = 'HKgaAKWjjgB9YRrTbTpHzw=='

$bmNotInstalledMsg = 'It looks like BuildMaster isn''t installed. Please run init.ps1 to install and configure a local BuildMaster instance so we can run automated tests against it.'
$svcRoot = Get-ItemProperty -Path 'hklm:\SOFTWARE\Inedo\BuildMaster' -Name 'ServicePath' | Select-Object -ExpandProperty 'ServicePath'
if( -not $svcRoot )
{
    throw $bmNotInstalledMsg
}

$svcConfig = [xml](Get-Content -Path (Join-Path -Path $svcRoot -ChildPath 'app_appSettings.config' -Resolve) -Raw)
if( -not $svcConfig )
{
    throw $bmNotInstalledMsg
}

$uri = $svcConfig.appSettings.SelectSingleNode('add[@key=''IntegratedWebServer.Prefixes'']').Attributes['value'].Value
$uri = $uri -replace '\*',$env:COMPUTERNAME
$connString = $svcConfig.appSettings.SelectSingleNode('add[@key=''Core.DbConnectionString'']').Attributes['value'].Value

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

function New-BMTestSession
{
    return New-BMSession -Uri $uri -ApiKey $apiKey
}

Export-ModuleMember -Function '*'