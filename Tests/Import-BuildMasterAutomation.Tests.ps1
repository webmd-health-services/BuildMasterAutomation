
Describe 'Import-BuildMasterAutomationPs1.when module isn''t loaded' {
    Remove-Module -Name 'BuildMasterAutomation' -Verbose:$false

    & (Join-Path -Path $PSScriptRoot -ChildPath '..\BuildMasterAutomation\Import-BuildMasterAutomation.ps1' -Resolve) -Verbose:$false

    It 'should import BuildMaster' {
        Get-Module -Name 'BuildMasterAutomation' | Should Not BeNullOrEmpty
    }
}

Describe 'Import-BuildMasterAutomationPs1.when module is loaded' {
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\BuildMasterAutomation\Import-BuildMasterAutomation.ps1' -Resolve) -Verbose:$false
    Get-Module -Name 'BuildMasterAutomation' | Add-Member -MemberType NoteProperty -Name 'Fubar' -Value 'Snafu'
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\BuildMasterAutomation\Import-BuildMasterAutomation.ps1' -Resolve) -Verbose:$false
    It 'should remove and import module' {
        $module = Get-Module -Name 'BuildMasterAutomation'
        $module | Get-Member -Name 'Fubar' | Should BeNullOrEmpty
    }        
}