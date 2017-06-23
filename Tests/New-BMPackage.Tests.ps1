
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession 
$app = New-BMTestApplication -Session $session -CommandPath $PSCommandPath
$pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())
$pipeline = New-BMPipeline -Session $session -Name $pipelineName -Application $app -Color '#ffffff'
$release = New-BMRelease -Session $session -Application $app -Number '1.0' -Pipeline $pipeline

function Assert-Package
{
    param(
        [Parameter(ValueFromPipeline=$true)]
        $Package,

        [object]
        $HasNumber,

        [hashtable]
        $HasVariable
    )

    It 'should return the package' {
        $Package | Should -Not -BeNullOrEmpty
    }

    $Package = Get-BMPackage -Session $session -Package $package
    Context 'the package' {
        It 'should exist' {
            $Package | Should -Not -BeNullOrEmpty
        }

        It 'should set the number' {
            $Package.number | Should -Be $HasNumber
        }

        It 'should set the application' {
            $Package.applicationId | Should -Be $app.Application_Id
        }

        It 'should set the pipeline' {
            $Package.pipelineId | Should -Be $pipeline.Pipeline_Id
        }

        It 'should set the release' {
            $Package.releaseId | Should -Be $release.id
        }

        $variable = Invoke-BMNativeApiMethod -Session $session -Name 'Variables_GetPackageVariables' -Parameter @{ 'Build_Id' = $Package.id }
        if( $HasVariable )
        {
            foreach( $key in $HasVariable.Keys )
            {
                $actualVariable = $variable |  Where-Object { $_.Variable_Name -eq $key }
                It ('should set {0} variable' -f $key) {
                    $actualVariable | Should -Not -BeNullOrEmpty
                    $value = $actualVariable.Variable_Value
                    $value = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($value))
                    $value | Should Be $HasVariable[$key]
                }
            }
        }
    }

}

Describe 'New-BMPackage.when creating package' {
    New-BMPackage -Session $session -Release $release |
        Assert-Package -HasNumber 1
}

Describe 'New-BMPackage.when creating package with custom name' {
    New-BMPackage -Session $session -Release $release -PackageNumber '56.develop' |
        Assert-Package -HasNumber '56.develop'
}

Describe 'New-BMPackage.when creating package with package variables' {
    $variable = @{ 'ProGetPackageName' = '17.125.56+develop.deadbee' } 
    New-BMPackage -Session $session -Release $release -PackageNumber '3' -Variable $variable |
        Assert-Package -HasNumber '3' -HasVariable $variable
}

Describe 'New-BMPackage.when creating with release number and application' {
    New-BMPackage -Session $session -ReleaseNumber $release.number -Application $app |
        Assert-Package -HasNumber '4'
}
