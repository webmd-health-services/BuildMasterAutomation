
$script:itemNum = 0

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

$url = $svcConfig.SelectSingleNode('/InedoAppConfig/WebServer').Attributes['Urls'].Value
$url = $url -replace '\*',$env:COMPUTERNAME
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
        $cmd.ExecuteNonQuery();
    }
}
finally
{
    $conn.Close()
}

function New-BMTestApplication
{
    [CmdletBinding(DefaultParameterSetName='ByCommandPath')]
    param(
        [Object] $Session,

        [Parameter(Mandatory, ParameterSetName='ByCommandPath')]
        [String]$CommandPath,

        [Parameter(Mandatory, ParameterSetName='ByName')]
        [String] $Name
    )

    if (-not $Name)
    {
        $Name = New-BMTestObjectName
    }

    return New-BMApplication -Session $Session -Name $Name
}

$script:session = New-BMSession -Url $url -ApiKey $apiKey
$script:objectNum = 0
$script:wordsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\.words'
$script:wordsPath = [IO.Path]::GetFullPath($script:wordsPath)
[String[]] $script:words = @()

function New-BMTestObjectName
{
    [CmdletBinding()]
    param(
    )

    if (-not (Test-Path -Path $script:wordsPath))
    {
        $script:words = Invoke-RestMethod -Uri 'https://random-word-api.herokuapp.com/all'
        $script:words | Set-Content -Path $script:wordsPath
    }

    if (-not $script:words)
    {
        $script:words = Get-Content -Path $script:wordsPath | Where-Object { $_ }
    }

    # Faster than piping.
    $word = Get-Random -InputObject $script:words

    $script:objectNum += 1
    $filesToSkip = @( $PSCommandPath, (Get-Module -Name 'Pester').Path )
    $baseName =
        Get-PSCallStack |
        Where-Object 'ScriptName' -NotIn $filesToSkip |
        Select-Object -First 1 |
        Select-Object -ExpandProperty 'ScriptName' |
        Split-Path -Leaf |
        ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) } |
        ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) }
    return "$($baseName).$($word)"
}

function New-BMTestSession
{
    return $script:session
}

function GivenAnApplication
{
    param(
        $Name,

        [switch] $ThatIsDisabled
    )

    $Name = New-BMTestObjectName

    $app = New-BMApplication -Session $script:session -Name $Name

    if( $ThatIsDisabled )
    {
        Disable-BMApplication -Session $script:session -ID $app.Application_Id |
            Out-String |
            Write-Debug
    }

    return $app
}

function GivenARelease
{
    param(
        $Named,

        [Parameter(Mandatory)]
        $ForApplication,

        [Parameter(Mandatory)]
        $WithNumber,

        [Parameter(Mandatory)]
        $UsingPipeline
    )

    $Named = New-BMTestObjectName

    return New-BMRelease -Session $script:session `
                         -Application $ForApplication `
                         -Number $WithNumber `
                         -Name $Named `
                         -Pipeline $UsingPipeline
}

function GivenAPipeline
{
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        [Parameter(Position=0)]
        $Named,

        [Parameter(ParameterSetName='Global')]
        [Object] $InRaft = $script:defaultRaft,

        [Parameter(ParameterSetName='Application')]
        $ForApplication
    )

    $Named = New-BMTestObjectName

    $setArgs = @{ }
    if ($ForApplication)
    {
        $setArgs['Application'] = $ForApplication
    }
    else
    {
        $setArgs['Raft'] = $InRaft
    }

    return Set-BMPipeline -Session $script:session -Name $Named @setArgs -PassThru
}

function GivenABuild
{
    [CmdletBinding(DefaultParameterSetName='WithAllTheTrimmings')]
    param(
        [Parameter(Mandatory, ParameterSetName='WithAllTheTrimmings')]
        [String] $ForAnAppNamed,

        [Parameter(Mandatory, ParameterSetName='WithAllTheTrimmings')]
        [String] $ForReleaseNumber,

        [Parameter(Mandatory, ParameterSetName='ForARelease')]
        $ForRelease
    )

    if( $PSCmdlet.ParameterSetName -eq 'ForARelease' )
    {
        return New-BMBuild -Session $script:session -Release $ForRelease
    }

    $app = GivenAnApplication -Name $ForAnAppNamed
    $pipeline = GivenAPipeline -Named "$($ForAnAppNamed).pipeline" -ForApplication $app
    $release = GivenARelease -Named "$($ForAnAppNamed).release" `
                             -ForApplication $app `
                             -WithNumber $ForReleaseNumber `
                             -UsingPipeline $pipeline
    return New-BMBuild -Session $script:session -Release $release
}

function ThenError
{
    param(
        [int] $AtIndex,

        [Parameter(Mandatory, Position=0, ParameterSetName='ShouldBeError')]
        [string] $MatchesPattern,

        [Parameter(Mandatory, ParameterSetName='NoErrors')]
        [switch] $IsEmpty
    )

    if ($PSBoundParameters.ContainsKey('AtIndex'))
    {
        $Global:Error[$AtIndex] | Should -Match $MatchesPattern
    }
    else
    {
        $Global:Error | Should -Match $MatchesPattern
    }

    if ($IsEmpty)
    {
        $Global:Error | Should -BeNullOrEmpty
    }
}

function ThenNoErrorWritten
{
    $Global:Error | Should -BeNullOrEmpty
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
$BMTestSession = $script:session

# Before BuildMaster is activated, the APIs return the licensing page HTML.
$waited = $false
do
{
    $result = Invoke-BMRestMethod -Session $script:session -Name 'infrastructure/servers/list'
    if ($result -isnot [String])
    {
        break
    }
    $result | Out-String | Write-Debug
    if (-not $waited)
    {
        Write-Host 'Waiting for BuildMaster activation' -NoNewline
    }
    Write-Host '.' -NoNewline
    $waited = $true
    Start-Sleep -Milliseconds 100
}
while ($true)

if ($waited)
{
    Write-Host ''
}

Get-BMApplication -Session $script:session | Remove-BMApplication -Session $script:session -Force
Get-BMPipeline -Session $script:session  | Remove-BMPipeline -Session $script:session -PurgeHistory

$script:defaultRaft = Set-BMRaft -Session $script:session -Raft 'BMAutomationDefaultTestRaft' -PassThru
Get-BMRaft -Session $script:session |
    Where-Object 'Raft_Name' -NE 'Default' |
    Where-Object 'Raft_Id' -NE $script:defaultRaft.Raft_Id |
    Remove-BMRaft -Session $script:session

Export-ModuleMember -Function '*' -Variable 'BMTestSession'