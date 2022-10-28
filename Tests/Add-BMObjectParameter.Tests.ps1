
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    function Assert-Contains
    {
        param(
            [Parameter(ValueFromPipeline)]
            [hashtable] $InputObject,

            [Parameter(Position=0)]
            $Name,

            [Parameter(Position=1)]
            $Value
        )

        $InputObject.ContainsKey($Name) | Should -BeTrue
        $InputObject[$Name] | Should -Be $Value
    }
}

Describe 'Add-BMObjectParameter' {
    It 'should add value of _Id property' {
        @{ } |
            Add-BMObjectParameter -Name 'fubar' -Value ([pscustomobject]@{ 'fubar_Id' = 45; }) -PassThru |
            Assert-Contains 'fubarId' 45
    }

    It 'should add value of id property' {
        @{ } |
            Add-BMObjectParameter -Name 'fubar' -Value ([pscustomobject]@{ 'id' = 45; }) -PassThru |
            Assert-Contains 'fubarId' 45
    }

    It 'should add value of _Name property' {
        @{ } |
            Add-BMObjectParameter -Name 'fubar' -Value ([pscustomobject]@{ 'fubar_Name' = '45'; }) -PassThru |
            Assert-Contains 'fubarName' '45'
    }

    It 'should add value of name property' {
        @{ } |
            Add-BMObjectParameter -Name 'fubar' -Value ([pscustomobject]@{ 'name' = '45'; }) -PassThru |
            Assert-Contains 'fubarName' '45'
    }

    It 'should add value if passed integer' {
        @{ } |
            Add-BMObjectParameter -Name 'fubar' -Value 45 -PassThru |
            Assert-Contains 'fubarId' '45'
    }

    It 'should add value if passed string' {
        @{ } |
            Add-BMObjectParameter -Name 'fubar' -Value '45' -PassThru |
            Assert-Contains 'fubarName' '45'
    }

    It 'should not return hashtable' {
        $parameters = @{ }
        $result = Add-BMObjectParameter -Parameter $parameters -Name 'fubar' -Value '45'
        $result | Should -BeNullOrEmpty
        Assert-Contains -InputObject $parameters 'fubarName' '45'
    }
}