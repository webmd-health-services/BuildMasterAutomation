
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

function Assert-Contains
{
    param(
        [Parameter(ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,
        [Parameter(Position=0)]
        $Name,
        [Parameter(Position=1)]
        $Value
    )

    Context ('parameter $($Name)Id') {
        It ('should exist' -f $Name) {
            $InputObject.ContainsKey($Name) | Should Be $true
        }

        It ('should be set' -f $Value) {
            $InputObject[$Name] | Should Be $Value
        }
    }
}

Describe 'Add-BMObjectParameter.when passed an object with $Name_ID property' {
    @{ } | Add-BMObjectParameter -Name 'fubar' -Value ([pscustomobject]@{ 'fubar_Id' = 45; }) -PassThru | Assert-Contains 'fubarId' 45
}

Describe 'Add-BMObjectParameter.when passed an object with id property' {
    @{ } | Add-BMObjectParameter -Name 'fubar' -Value ([pscustomobject]@{ 'id' = 45; }) -PassThru | Assert-Contains 'fubarId' 45
}

Describe 'Add-BMObjectParameter.when passed an object with $Name_Name property' {
    @{ } | Add-BMObjectParameter -Name 'fubar' -Value ([pscustomobject]@{ 'fubar_Name' = '45'; }) -PassThru | Assert-Contains 'fubarName' '45'
}

Describe 'Add-BMObjectParameter.when passed an object with name property' {
    @{ } | Add-BMObjectParameter -Name 'fubar' -Value ([pscustomobject]@{ 'name' = '45'; }) -PassThru | Assert-Contains 'fubarName' '45'
}

Describe 'Add-BMObjectParameter.when passed an integer' {
    @{ } | Add-BMObjectParameter -Name 'fubar' -Value 45 -PassThru | Assert-Contains 'fubarId' '45'
}

Describe 'Add-BMObjectParameter.when passed a name' {
    @{ } | Add-BMObjectParameter -Name 'fubar' -Value '45' -PassThru | Assert-Contains 'fubarName' '45'
}

Describe 'Add-BMObjectParameter.when PassThru switch not used' {
    $parameters = @{ } 
    
    $result = Add-BMObjectParameter -Parameter $parameters -Name 'fubar' -Value '45' 
    
    It 'should not return anything' {
        $result | Should -BeNullOrEmpty
    }


    Assert-Contains -InputObject $parameters 'fubarName' '45'
}
