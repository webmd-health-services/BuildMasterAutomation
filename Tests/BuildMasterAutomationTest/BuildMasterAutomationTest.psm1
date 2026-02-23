
$apiKey = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\.apikey' -Resolve) -ReadCount 1
$url = "http://$([Environment]::MachineName):8622/"
$script:session = New-BMSession -Url $url -ApiKey $apiKey

$script:objectNum = 0
$script:wordsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\.words'
$script:wordsPath = [IO.Path]::GetFullPath($script:wordsPath)
[String[]] $script:words = @()

function New-BMTestObjectName
{
    [CmdletBinding()]
    param(
        [String] $Separator
    )

    if (-not (Test-Path -Path $script:wordsPath))
    {
        $wordsUrl = 'https://raw.githubusercontent.com/first20hours/google-10000-english/refs/heads/master/google-10000-english-usa-no-swears-medium.txt'
        $ProgressPreference = 'SilentlyContinue'
        $rawWords = Invoke-WebRequest -Uri $wordsUrl -UseBasicParsing | Select-Object -ExpandProperty 'Content'
        $rawWords.TrimEnd() | Set-Content -Path $script:wordsPath -NoNewLine
    }

    if (-not $script:words)
    {
        $script:words = Get-Content -Path $script:wordsPath
    }

    # Faster than piping.
    $word = ''
    do
    {
        $ceiling = $script:words.Count - 1
        $wordIdx = Get-Random -Minimum 0 -Maximum $ceiling
        $word = $script:words[$wordIdx]
    }
    while (-not $word)

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

    if (-not $Separator)
    {
        $Separator = '.'
    }

    return "${baseName}${Separator}${word}"
}

function New-BMTestSession
{
    return $script:session
}

function GivenAnApplication
{
    param(
        [Parameter(Mandatory)]
        $Name,

        [switch] $ThatIsDisabled
    )

    $Name = Split-Path -Path $Name -Leaf
    $Name = '{0}.{1}' -f $Name,[IO.Path]::GetRandomFileName()

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
        [Parameter(Mandatory)]
        $Named,

        [Parameter(Mandatory)]
        $ForApplication,

        [Parameter(Mandatory)]
        $WithNumber,

        [Parameter(Mandatory)]
        $UsingPipeline
    )

    $Named = Split-Path -Path $Named -Leaf
    $Named = '{0}.{1}' -f $Named,[IO.Path]::GetRandomFileName()

    return New-BMRelease -Session $script:session -Application $ForApplication -Number $WithNumber -Name $Named -Pipeline $UsingPipeline
}

function GivenAPipeline
{
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        [Parameter(Mandatory, Position=0)]
        $Named,

        [Parameter(ParameterSetName='Global')]
        [Object] $InRaft = $script:defaultRaft,

        [Parameter(ParameterSetName='Application')]
        $ForApplication
    )

    $Named = Split-Path -Path $Named -Leaf
    $Named = '{0}.{1}' -f $Named,[IO.Path]::GetRandomFileName()

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

function ClearBM
{
    Get-BMApplication -Session $script:session | Remove-BMApplication -Session $script:session -Force
    Get-BMPipeline -Session $script:session | Remove-BMPipeline -Session $script:session -PurgeHistory

    $script:defaultRaft = Set-BMRaft -Session $script:session -Raft 'BMAutomationDefaultTestRaft' -PassThru
    Get-BMRaft -Session $script:session |
        Where-Object 'Raft_Name' -NE 'Default' |
        Where-Object 'Raft_Id' -NE $script:defaultRaft.Raft_Id |
        Remove-BMRaft -Session $script:session
}
ClearBM

Export-ModuleMember -Function '*' -Variable 'BMTestSession'
