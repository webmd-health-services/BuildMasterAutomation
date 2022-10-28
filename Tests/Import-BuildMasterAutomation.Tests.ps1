
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    $script:importPath =
        Join-Path -Path $PSScriptRoot -ChildPath '..\BuildMasterAutomation\Import-BuildMasterAutomation.ps1' -Resolve
}

Describe 'Import-BuildMasterAutomationPs1' {
    It 'should import BuildMaster' {
        Remove-Module -Name 'BuildMasterAutomation' -Verbose:$false -ErrorAction Ignore
        & $script:importPath -Verbose:$false
        Get-Module -Name 'BuildMasterAutomation' | Should -Not -BeNullOrEmpty
    }

    It 'should remove and import module' {
        & $script:importPath -Verbose:$false
        Get-Module -Name 'BuildMasterAutomation' | Add-Member -MemberType NoteProperty -Name 'Fubar' -Value 'Snafu'
        & $script:importPath -Verbose:$false
        $module = Get-Module -Name 'BuildMasterAutomation'
        $module | Get-Member -Name 'Fubar' | Should -BeNullOrEmpty
    }
}
