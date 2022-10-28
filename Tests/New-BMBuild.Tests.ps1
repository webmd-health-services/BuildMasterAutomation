
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:app = New-BMTestApplication -Session $script:session -CommandPath $PSCommandPath
    $script:pipelineName = ('{0}.{1}' -f (Split-Path -Path $PSCommandPath -Leaf),[IO.Path]::GetRandomFileName())
    $script:pipeline =
        New-BMPipeline -Session $script:session -Name $script:pipelineName -Application $script:app -Color '#ffffff'
    $script:release =
        New-BMRelease -Session $script:session -Application $script:app -Number '1.0' -Pipeline $script:pipeline

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

        $Package | Should -Not -BeNullOrEmpty
        $Package = Get-BMPackage -Session $script:session -Package $package
        $Package | Should -Not -BeNullOrEmpty
        $Package.number | Should -Be $HasNumber
        $Package.applicationId | Should -Be $script:app.Application_Id
        $Package.pipelineId | Should -Be $script:pipeline.Pipeline_Id
        $Package.releaseId | Should -Be $script:release.id

        if( $HasVariable )
        {
            $variable = Invoke-BMNativeApiMethod -Session $script:session `
                                                 -Name 'Variables_GetPackageVariables' `
                                                 -Parameter @{ 'Build_Id' = $Package.id } `
                                                 -Method Post

            foreach( $key in $HasVariable.Keys )
            {
                $actualVariable = $variable |  Where-Object { $_.Variable_Name -eq $key }
                $actualVariable | Should -Not -BeNullOrEmpty
                $value = $actualVariable.Variable_Value
                $value = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($value))
                $value | Should -Be $HasVariable[$key]
            }
        }
    }
}

Describe 'New-BMPackage' {
    It 'should create package' {
        New-BMPackage -Session $script:session -Release $script:release |
            Assert-Package -HasNumber 1
    }

    It 'should create package with custom name' {
        New-BMPackage -Session $script:session -Release $script:release -PackageNumber '56.develop' |
            Assert-Package -HasNumber '56.develop'
    }

    It 'should create package with variables' {
        $variable = @{ 'ProGetPackageName' = '17.125.56+develop.deadbee' }
        New-BMPackage -Session $script:session -Release $script:release -PackageNumber '3' -Variable $variable |
            Assert-Package -HasNumber '3' -HasVariable $variable
    }

    It 'create package with release number and application' {
        New-BMPackage -Session $script:session -ReleaseNumber $script:release.number -Application $script:app |
            Assert-Package -HasNumber '4'
    }
}