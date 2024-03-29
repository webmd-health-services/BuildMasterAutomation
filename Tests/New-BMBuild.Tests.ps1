
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $defaultObjectName = New-BMTestObjectName
    $raft = Set-BMRaft -Session $script:session -Raft $defaultObjectName -PassThru
    $script:app = New-BMApplication -Session $script:session -Name $defaultObjectName -Raft $raft
    $script:pipeline = Set-BMPipeline -Session $script:session `
                                      -Name $defaultObjectName `
                                      -Application $app `
                                      -Color '#ffffff' `
                                      -PassThru
    $script:release =
        New-BMRelease -Session $script:session -Application $script:app -Number '1.0' -Pipeline $script:pipeline

    function Assert-Build
    {
        param(
            [Parameter(ValueFromPipeline=$true)]
            $Build,

            [object]
            $HasNumber,

            [hashtable]
            $HasVariable
        )

        $Build | Should -Not -BeNullOrEmpty
        $Build = Get-BMBuild -Session $script:session -Build $Build
        $Build | Should -Not -BeNullOrEmpty
        $Build.number | Should -Be $HasNumber
        $Build.applicationId | Should -Be $script:app.Application_Id
        $Build.pipelineName | Should -Be $script:pipeline.Pipeline_Name
        $Build.releaseId | Should -Be $script:release.id

        if( $HasVariable )
        {
            $variable = Invoke-BMNativeApiMethod -Session $session `
                                                 -Name 'Variables_GetBuildVariables' `
                                                 -Parameter @{ 'Build_Id' = $Build.id } `
                                                 -Method Post

            foreach( $key in $HasVariable.Keys )
            {
                $actualVariable = $variable |  Where-Object { $_.Variable_Name -eq $key }
                $actualVariable | Should -Not -BeNullOrEmpty
                $value = $actualVariable.Variable_Value
                $value = $value | ConvertFrom-BMNativeApiByteValue
                $value | Should -Be $HasVariable[$key]
            }
        }
    }
}

Describe 'New-BMBuild' {
    It 'should create build' {
        New-BMBuild -Session $script:session -Release $script:release |
            Assert-Build -HasNumber 1
    }

    It 'should create build with custom name' {
        New-BMBuild -Session $script:session -Release $script:release -BuildNumber '56.develop' |
            Assert-Build -HasNumber '56.develop'
    }

    It 'should create build with variables' {
        $variable = @{ 'ProGetPackageName' = '17.125.56+develop.deadbee' }
        New-BMBuild -Session $script:session -Release $script:release -BuildNumber '3' -Variable $variable |
            Assert-Build -HasNumber '3' -HasVariable $variable
    }

    It 'create build with release number and application' {
        New-BMBuild -Session $script:session -ReleaseNumber $script:release.number -Application $script:app |
            Assert-Build -HasNumber '4'
    }

    It 'should export obsolete New-BMPackage' {
        $warnings = @()
        New-BMPackage -Session $script:session -Release $script:release -WarningVariable 'warnings' |
            Assert-Build -HasNumber '5'
        $warnings | Should -Not -BeNullOrEmpty
    }
}