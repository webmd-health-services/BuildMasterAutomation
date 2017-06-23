
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

[object[]]$result = $null

function ThenDidNotReturn
{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        $Description,

        [Parameter(mandatory=$true,Position=1)]
        [object[]]
        $Package
    )

    It ('should not return {0} packages' -f $Description) {
        foreach( $item in $Package )
        {
            $foundPackage = $result | Where-Object { $_.id -eq $item.id } 
            $foundPackage | Should -BeNullOrEmpty
        }
    }
}

function ThenReturnedPackages
{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        $Description,

        [Parameter(Mandatory=$true,Position=1)]
        [object[]]
        $Package
    )

    It ('should return {0} packages' -f $Description) {
        foreach( $item in $Package )
        {
            $result | Where-Object { $_.id -eq $item.id } | Should -Not -BeNullOrEmpty
        }
    }
}

function ThenReturnedPackage
{
    param(
        $Package
    )

    It ('should return just that package') {
        $Script:result.Count | Should -Be 1
        $script:result[0].id | Should -Be $Package.id
    }
}

function WhenGettingAllPackages
{
    $script:result = Get-BMPackage -Session $BMTestSession
}

function WhenGettingPackage
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $Package
    )

    $script:result = Get-BMPackage -Session $BMTestSession -Package $Package
}

function WhenGettingPackagesByRelease
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $Release
    )

    $script:result = Get-BMPackage -Session $BMTestSession -Release $Release
}


Describe 'Get-BMPackage.when given no parameters' {
    $pipeline = GivenAPipeline -Named $PSCommandPath

    $app1 = GivenAnApplication -Name $PSCommandPath
    $app1Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '1.0.0' -UsingPipeline $pipeline
    $app1Release1Package1 = GivenAPackage -ForRelease $app1Release1
    $app1Release1Package2 = GivenAPackage -ForRelease $app1Release1

    $app1Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '2.0.0' -UsingPipeline $pipeline
    $app1Release2Package1 = GivenAPackage -ForRelease $app1Release2

    $app2 = GivenAnApplication -Name $PSCommandPath
    $app2Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '1.0.0' -UsingPipeline $pipeline
    $app2Release1Package1 = GivenAPackage -ForRelease $app2Release1
    $app2Release1Package2 = GivenAPackage -ForRelease $app2Release1
        
    $app2Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '2.0.0' -UsingPipeline $pipeline
    $app2Release2Package1 = GivenAPackage -ForRelease $app2Release2

    WhenGettingAllPackages

    ThenReturnedPackages 'all' $app1Release1Package1,$app1Release1Package2,$app1Release2Package1,$app2Release1Package1,$app2Release1Package2,$app2Release2Package1
}

Describe 'Get-BMPackage.when passed a package object' {
    $package = GivenAPackage -ForAnAppNamed $PSCommandPath -ForReleaseNumber '1.0.0'
    WhenGettingPackage $package
    ThenReturnedPackage $package
}

Describe 'Get-BMPackage.when passed a package ID' {
    $package = GivenAPackage -ForAnAppNamed $PSCommandPath -ForReleaseNumber '1.0.0'
    WhenGettingPackage $package.id
    ThenReturnedPackage $package
}


Describe 'Get-BMPackage.when passed a release object' {
    $pipeline = GivenAPipeline -Named $PSCommandPath

    $app1 = GivenAnApplication -Name $PSCommandPath
    $app1Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '1.0.0' -UsingPipeline $pipeline
    $app1Release1Package1 = GivenAPackage -ForRelease $app1Release1
    $app1Release1Package2 = GivenAPackage -ForRelease $app1Release1

    $app1Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '2.0.0' -UsingPipeline $pipeline
    $app1Release2Package1 = GivenAPackage -ForRelease $app1Release2

    $app2 = GivenAnApplication -Name $PSCommandPath
    $app2Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '1.0.0' -UsingPipeline $pipeline
    $app2Release1Package1 = GivenAPackage -ForRelease $app2Release1
    $app2Release1Package2 = GivenAPackage -ForRelease $app2Release1
        
    $app2Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '2.0.0' -UsingPipeline $pipeline
    $app2Release2Package1 = GivenAPackage -ForRelease $app2Release2

    WhenGettingPackagesByRelease $app1Release1
    ThenReturnedPackages 'that release''s' $app1Release1Package1,$app1Release1Package2
    ThenDidNotReturn 'other releases''' $app1Release2Package1,$app2Release1Package1, $app2Release1Package2, $app2Release2Package1
}

Describe 'Get-BMPackage.when passed a release id' {
    $pipeline = GivenAPipeline -Named $PSCommandPath

    $app1 = GivenAnApplication -Name $PSCommandPath
    $app1Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '1.0.0' -UsingPipeline $pipeline
    $app1Release1Package1 = GivenAPackage -ForRelease $app1Release1
    $app1Release1Package2 = GivenAPackage -ForRelease $app1Release1

    $app1Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app1 -WithNumber '2.0.0' -UsingPipeline $pipeline
    $app1Release2Package1 = GivenAPackage -ForRelease $app1Release2

    $app2 = GivenAnApplication -Name $PSCommandPath
    $app2Release1 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '1.0.0' -UsingPipeline $pipeline
    $app2Release1Package1 = GivenAPackage -ForRelease $app2Release1
    $app2Release1Package2 = GivenAPackage -ForRelease $app2Release1
        
    $app2Release2 = GivenARelease -Named $PSCommandPath -ForApplication $app2 -WithNumber '2.0.0' -UsingPipeline $pipeline
    $app2Release2Package1 = GivenAPackage -ForRelease $app2Release2

    WhenGettingPackagesByRelease $app1Release1.id
    ThenReturnedPackages 'that release''s' $app1Release1Package1,$app1Release1Package2
    ThenDidNotReturn 'other releases''' $app1Release2Package1,$app2Release1Package1, $app2Release1Package2, $app2Release2Package1
}
