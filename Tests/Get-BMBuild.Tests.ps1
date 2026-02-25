
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    [object[]]$script:result = $null

    function ThenDidNotReturn
    {
        param(
            [Parameter(Mandatory=$true,Position=0)]
            [string]
            $Description,

            [Parameter(mandatory=$true,Position=1)]
            [object[]]
            $Build
        )

        foreach( $item in $Build )
        {
            $foundBuild = $script:result | Where-Object { $_.id -eq $item.id }
            $foundBuild | Should -BeNullOrEmpty
        }
    }

    function ThenReturnedBuilds
    {
        param(
            [Parameter(Mandatory=$true,Position=0)]
            [string]
            $Description,

            [Parameter(Mandatory=$true,Position=1)]
            [object[]]
            $Build
        )

        foreach( $item in $Build )
        {
            $script:result | Where-Object { $_.id -eq $item.id } | Should -Not -BeNullOrEmpty
        }
    }

    function ThenReturnedBuild
    {
        param(
            $Build
        )

        $script:result.Count | Should -Be 1
        $script:result[0].id | Should -Be $Build.id
    }

    function WhenGettingAllBuilds
    {
        $script:result = Get-BMBuild -Session $BMTestSession
    }

    function WhenGettingBuild
    {
        param(
            [Parameter(Mandatory=$true)]
            [object]
            $Build
        )

        $script:result = Get-BMBuild -Session $BMTestSession -Build $Build
    }

    function WhenGettingBuildsByRelease
    {
        param(
            [Parameter(Mandatory=$true)]
            [object]
            $Release
        )

        $script:result = Get-BMBuild -Session $BMTestSession -Release $Release
    }
}

Describe 'Get-BMBuild' {
    BeforeEach {
        $Global:Error.Clear()
        $script:result = @()
    }

    It 'should return all builds' {
        $pipeline = GivenAPipeline -Named $PSCommandPath

        $app1 = GivenAnApplication -Name $PSCommandPath
        $app1Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '1.0.0' -UsingPipeline $pipeline
        $app1Release1Build1 = GivenABuild -ForRelease $app1Release1
        $app1Release1Build2 = GivenABuild -ForRelease $app1Release1

        $app1Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '2.0.0' -UsingPipeline $pipeline
        $app1Release2Build1 = GivenABuild -ForRelease $app1Release2

        $app2 = GivenAnApplication -Name $PSCommandPath
        $app2Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '1.0.0' -UsingPipeline $pipeline
        $app2Release1Build1 = GivenABuild -ForRelease $app2Release1
        $app2Release1Build2 = GivenABuild -ForRelease $app2Release1

        $app2Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '2.0.0' -UsingPipeline $pipeline
        $app2Release2Build1 = GivenABuild -ForRelease $app2Release2

        WhenGettingAllBuilds

        ThenReturnedBuilds 'all' $app1Release1Build1,$app1Release1Build2,$app1Release2Build1,$app2Release1Build1,$app2Release1Build2,$app2Release2Build1
    }

    It 'should return specific build using build object' {
        $build = GivenABuild -ForAnAppNamed $PSCommandPath -ForReleaseNumber '1.0.0'
        WhenGettingBuild $build
        ThenReturnedBuild $build
    }

    It 'should return specific build using build id' {
        $build = GivenABuild -ForAnAppNamed $PSCommandPath -ForReleaseNumber '1.0.0'
        WhenGettingBuild $build.id
        ThenReturnedBuild $build
    }

    It 'should return build when passed release object' {
        $pipeline = GivenAPipeline -Named $PSCommandPath

        $app1 = GivenAnApplication -Name $PSCommandPath
        $app1Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '1.0.0' -UsingPipeline $pipeline
        $app1Release1Build1 = GivenABuild -ForRelease $app1Release1
        $app1Release1Build2 = GivenABuild -ForRelease $app1Release1

        $app1Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '2.0.0' -UsingPipeline $pipeline
        $app1Release2Build1 = GivenABuild -ForRelease $app1Release2

        $app2 = GivenAnApplication -Name $PSCommandPath
        $app2Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '1.0.0' -UsingPipeline $pipeline
        $app2Release1Build1 = GivenABuild -ForRelease $app2Release1
        $app2Release1Build2 = GivenABuild -ForRelease $app2Release1

        $app2Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '2.0.0' -UsingPipeline $pipeline
        $app2Release2Build1 = GivenABuild -ForRelease $app2Release2

        WhenGettingBuildsByRelease $app1Release1
        ThenReturnedBuilds 'that release''s' $app1Release1Build1,$app1Release1Build2
        ThenDidNotReturn 'other releases''' $app1Release2Build1,$app2Release1Build1, $app2Release1Build2, $app2Release2Build1
    }

    It 'should return build when passed release id' {
        $pipeline = GivenAPipeline -Named $PSCommandPath

        $app1 = GivenAnApplication -Name $PSCommandPath
        $app1Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '1.0.0' -UsingPipeline $pipeline
        $app1Release1Build1 = GivenABuild -ForRelease $app1Release1
        $app1Release1Build2 = GivenABuild -ForRelease $app1Release1

        $app1Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '2.0.0' -UsingPipeline $pipeline
        $app1Release2Build1 = GivenABuild -ForRelease $app1Release2

        $app2 = GivenAnApplication -Name $PSCommandPath
        $app2Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '1.0.0' -UsingPipeline $pipeline
        $app2Release1Build1 = GivenABuild -ForRelease $app2Release1
        $app2Release1Build2 = GivenABuild -ForRelease $app2Release1

        $app2Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '2.0.0' -UsingPipeline $pipeline
        $app2Release2Build1 = GivenABuild -ForRelease $app2Release2

        WhenGettingBuildsByRelease $app1Release1.id
        ThenReturnedBuilds 'that release''s' $app1Release1Build1,$app1Release1Build2
        ThenDidNotReturn 'other releases''' $app1Release2Build1,$app2Release1Build1, $app2Release1Build2, $app2Release2Build1
    }
}
