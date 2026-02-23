
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:testName = $null

    function GivenApp
    {
        param(
            [String] $Named
        )

        $name = "${script:testName} ${Named}"
        New-BMApplication -Session $script:session -Name $name
    }

    function GivenPipeline
    {
        param(
            [String] $Named,

            [String] $InAppNamed
        )

        $setBMPipelineArgs = @{}
        if ($InAppNamed)
        {
            $setBMPipelineArgs['Application'] = "${script:testName} ${InAppNamed}"
        }
        else
        {
            $setBMPipelineArgs['Raft'] = 1
        }

        $name = "${script:testName} ${Named}"
        Set-BMPipeline -Session $script:session -Name $name @setBMPipelineArgs -PassThru
    }

    function Assert-Release
    {
        param(
            [Parameter(ValueFromPipeline)]
            $Release,

            $HasNumber,

            $HasName
        )

        process
        {
            $Release | Should -Not -BeNullOrEmpty
            $newRelease = $Release | Get-BMRelease -Session $script:session
            $newRelease | Should -Not -BeNullOrEmpty
            $newRelease.id | Should -Be $Release.id
            $Release.applicationId | Should -Be $script:app.Application_Id
            $Release.number | Should -Be $HasNumber
            $Release.pipelineName | Should -Be $pipeline.Pipeline_Name

            if( -not $HasName )
            {
                $HasName = $HasNumber
            }
            $Release.name | Should -Be $HasName
        }
    }

    function ThenError
    {
        param(
            [String] $MatchesRegex
        )

        $Global:Error | Should -Match $MatchesRegex
    }

    function ThenRelease
    {
        param(
            [Parameter(Mandatory, ParameterSetName='Exists')]
            [String] $Numbered,

            [Parameter(ParameterSetName='Exists')]
            [String] $Named,

            [Parameter(Mandatory, ParameterSetName='Not')]
            [switch] $Not,

            [Parameter(Mandatory, ParameterSetName='Not')]
            [Parameter(Mandatory, ParameterSetName='Exists')]
            [switch] $Exists,

            [Parameter(Mandatory)]
            [String] $InAppNamed,

            [Parameter(Mandatory, ParameterSetName='Exists')]
            [String] $UsingPipelineNamed,

            [Parameter(ParameterSetName='Exists')]
            [String] $AndPipelineRaftPrefixIs
        )

        $appName = "${script:testName} ${InAppNamed}"

        if ($Not)
        {
            Get-BMRelease -Session $script:session -Application $appName | Should -BeNullOrEmpty
            return
        }

        if ($Named)
        {
            $Named = "${script:testName} ${Named}"
        }
        else
        {
            $Named = $Numbered
        }

        $pipelineName = "${script:testName} ${UsingPipelineNamed}"

        if ($AndPipelineRaftPrefixIs)
        {
            $pipelineName = "${AndPipelineRaftPrefixIs}::${pipelineName}"
        }

        $release = Get-BMRelease -Session $script:session -Application $appName -Release $Named
        $release | Should -Not -BeNullOrEmpty

        $release.number | Should -Be $Numbered
        $release.pipelineName | Should -Be $pipelineName
    }

    function WhenCreatingRelease
    {
        param(
            [hashtable] $WithArgs,

            [String] $Named,

            [String] $UsingPipelineNamed,

            [String] $InAppNamed
        )

        if ($Named)
        {
            $WithArgs['Name'] = "${script:testName} ${Named}"
        }

        if ($UsingPipelineNamed)
        {
            $WithArgs['Pipeline'] = "${script:testName} ${UsingPipelineNamed}"
        }

        if ($InAppNamed)
        {
            $WithArgs['Application'] = "${script:testName} ${InAppNamed}"
        }

        New-BMRelease -Session $script:session @WithArgs
    }

    function New-TestReleaseNumber
    {
        [IO.Path]::GetRandomFileName()
    }
}

AfterAll {
    $apps = Get-BMApplication -Session $script:session | Where-Object 'Application_Name' -Like 'New-BMRelease*'
    $apps | Disable-BMApplication -Session $script:session
    $apps | Remove-BMApplication -Session $script:session

    Get-BMPipeline -Session $script:session |
        Where-Object 'RaftItem_Name' -Like 'New-BMRelease*' |
        Remove-BMPipeline -Session $script:session -PurgeHistory
}

Describe 'New-BMRelease' {
    BeforeEach {
        $script:testName = New-BMTestObjectName
        $Global:Error.Clear()
    }

    It 'accepts piped application' {
        $app = GivenApp '10'
        $pipeline = GivenPipeline '11'
        $app | New-BMRelease -Session $script:session -Number '12.0.0' -Pipeline $pipeline
        ThenRelease -Numbered '12.0.0' `
                    -Exists `
                    -InAppNamed '10' `
                    -UsingPipelineNamed '11' `
                    -AndPipelineRaftPrefixIs 'global'
    }

    It 'accepts application and pipeline names' {
        GivenApp '20'
        GivenPipeline '21'
        WhenCreatingRelease -UsingPipelineNamed '21' -InAppNamed '20' -WithArgs @{ Number = '22.0.0' }
        ThenRelease -Numbered '22.0.0' `
                    -Exists `
                    -InAppNamed '20' `
                    -UsingPipelineNamed '21' `
                    -AndPipelineRaftPrefixIs 'global'
    }

    It 'accepts application and pipeline ids' {
        $app = GivenApp '30'
        $pipeline = GivenPipeline '31'
        WhenCreatingRelease -WithArgs @{
            Application = $app.Application_Id
            Pipeline = $pipeline.RaftItem_Id
            Number = '32.0.0'
        }
        ThenRelease -Numbered '32.0.0' `
                    -Exists `
                    -InAppNamed '30' `
                    -UsingPipelineNamed '31' `
                    -AndPipelineRaftPrefixIs 'global'
    }

    It 'accepts application and pipeline objects' {
        $app = GivenApp '40'
        $pipeline = GivenPipeline '41'
        WhenCreatingRelease -WithArgs @{ Application = $app ; Pipeline = $pipeline ; Number = '42.0.0' }
        ThenRelease -Numbered '42.0.0' `
                    -Exists `
                    -InAppNamed '40' `
                    -UsingPipelineNamed '41' `
                    -AndPipelineRaftPrefixIs 'global'
    }

    It 'sets release name' {
        GivenApp '50'
        GivenPipeline '51'
        WhenCreatingRelease -Named '52' -UsingPipelineNamed '51' -InAppNamed '50' -WithArgs @{ Number = '52.0.0' }
        ThenRelease -Numbered '52.0.0' `
                    -Exists `
                    -Named '52' `
                    -InAppNamed '50' `
                    -UsingPipelineNamed '51' `
                    -AndPipelineRaftPrefixIs 'global'
    }

    It 'uses application-specific pipeline' {
        GivenApp '60'
        GivenPipeline '61' -InAppNamed '60'
        WhenCreatingRelease -UsingPipelineNamed '61' -InAppNamed '60' -WithArgs @{ Number = '62.0.0' }
        ThenRelease -Numbered '62.0.0' `
                    -Exists `
                    -InAppNamed '60' `
                    -UsingPipelineNamed '61'
    }

    It 'accepts global pipeline' {
        GivenApp '70'
        GivenPipeline '71' # Global
        WhenCreatingRelease -UsingPipelineNamed '71' -InAppNamed '70' -WithArgs @{ Number = '72.0.0' }
        ThenRelease -Numbered '72.0.0' `
                    -Exists `
                    -InAppNamed '70' `
                    -UsingPipelineNamed '71' `
                    -AndPipelineRaftPrefixIs 'global'
    }

    Context 'app and global pipelines have the same name' {
        Context 'passing pipeline name' {
            It 'writes an error' {
                GivenApp '80'
                GivenPipeline '81'
                GivenPipeline '81' -InAppNamed '80'
                WhenCreatingRelease -UsingPipelineNamed '81' `
                                    -InAppNamed '80' `
                                    -WithArgs @{ Number = '82.0.0' ; ErrorAction = 'SilentlyContinue' }
                ThenRelease -Not -Exists -InAppNamed '80'
                ThenError -Matches 'there are 2 ".*81" pipelines'
            }
        }

        Context 'passing global pipeline ID' {
            It 'uses global pipeline' {
                GivenApp '90'
                $pipeline = GivenPipeline '91'
                GivenPipeline '91' -InAppNamed '90'
                WhenCreatingRelease -InAppNamed '90' -WithArgs @{ Number = '92.0.0' ; Pipeline = $pipeline.RaftItem_Id }
                ThenRelease -Numbered '92.0.0' `
                            -Exists `
                            -InAppNamed '90' `
                            -UsingPipelineNamed '91' `
                            -AndPipelineRaftPrefixIs 'global'
            }
        }

        Context 'passing app pipeline ID' {
            It 'uses app pipeline' {
                GivenApp '100'
                GivenPipeline '101'
                $pipeline = GivenPipeline '101' -InAppNamed '100'
                WhenCreatingRelease -InAppNamed '100' `
                                    -WithArgs @{ Number = '102.0.0' ; Pipeline = $pipeline.RaftItem_Id }
                ThenRelease -Numbered '102.0.0' `
                            -Exists `
                            -InAppNamed '100' `
                            -UsingPipelineNamed '101'
            }
        }

        Context 'passing global pipeline object' {
            It 'uses global pipeline' {
                GivenApp '110'
                $pipeline = GivenPipeline '111'
                GivenPipeline '111' -InAppNamed '110'
                WhenCreatingRelease -InAppNamed '110' -WithArgs @{ Number = '112.0.0' ; Pipeline = $pipeline }
                ThenRelease -Numbered '112.0.0' `
                            -Exists `
                            -InAppNamed '110' `
                            -UsingPipelineNamed '111' `
                            -AndPipelineRaftPrefixIs 'global'
            }
        }

        Context 'passing app pipeline object' {
            It 'uses app pipeline' {
                GivenApp '110'
                GivenPipeline '111'
                $pipeline = GivenPipeline '111' -InAppNamed '110'
                WhenCreatingRelease -InAppNamed '110' -WithArgs @{ Number = '112.0.0' ; Pipeline = $pipeline }
                ThenRelease -Numbered '112.0.0' `
                            -Exists `
                            -InAppNamed '110' `
                            -UsingPipelineNamed '111'
            }
        }
    }

    It 'requires pipeline' {
        GivenApp '120'
        WhenCreatingRelease -InAppNamed '120' `
                            -UsingPipelineNamed '121' `
                            -WithArgs @{ Number = '122.0.0.' ; ErrorAction = 'SilentlyContinue' }
        ThenRelease -Not -Exists -InAppNamed '120'
        ThenError -Matches 'pipeline ".*121" does not exist'
    }
}