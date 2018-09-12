
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession

Describe 'Invoke-BMNativeApiMethod.when using WhatIf switch and GET HTTP method' {
    $variable = @{
                    'Variable_Name' = 'Fubar';
                    'Variable_Value' = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes('Snafu'))
                    'ValueType_Code' = 'string';
                    'Sensitive_Indicator' = 'False';
                    'EvaluateVariables_Indicator' = 'False';
                }
    Invoke-BMNativeApiMethod -Session $session -Name 'Variables_CreateOrUpdateVariable' -Method Post -Parameter $variable
    $result = Invoke-BMNativeApiMethod -Session $session -Name 'Variables_GetVariables' -WhatIf
    It ('should return a result') {
        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-BMNativeApiMethod.when using WhatIf switch and POST HTTP method' {
    $encodedValue = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes('Snafu'))
    $variable = @{
                    'Variable_Name' = 'Fubar';
                    'Variable_Value' = $encodedValue;
                    'ValueType_Code' = 'string';
                    'Sensitive_Indicator' = 'False';
                    'EvaluateVariables_Indicator' = 'False';
                }
    Invoke-BMNativeApiMethod -Session $session -Name 'Variables_CreateOrUpdateVariable' -Method Post -Parameter $variable
    $variable['Variable_Value'] = 'FizzBuzz'
    Invoke-BMNativeApiMethod -Session $session -Name 'Variables_CreateOrUpdateVariable' -Method Post -Parameter $variable -WhatIf
    $result = Invoke-BMNativeApiMethod -Session $session -Name 'Variables_GetVariables'
    It ('should not make the HTTP request') {
        $result.Variable_Value | Should -Be $encodedValue
    }
}
