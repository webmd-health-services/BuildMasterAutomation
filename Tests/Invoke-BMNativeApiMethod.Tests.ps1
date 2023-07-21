
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
}

Describe 'Invoke-BMNativeApiMethod' {
    It 'should return a result when making GET requests and WhatIf is true' {
        $variable = @{
                        'Variable_Name' = 'Fubar';
                        'Variable_Value' = ('Snafu' | ConvertTo-BMNativeApiByteValue);
                        'ValueType_Code' = 'string';
                        'Sensitive_Indicator' = 'False';
                        'EvaluateVariables_Indicator' = 'False';
                    }
        Invoke-BMNativeApiMethod -Session $script:session -Name 'Variables_CreateOrUpdateVariable' -Method Post -Parameter $variable
        $result = Invoke-BMNativeApiMethod -Session $script:session -Name 'Variables_GetVariables' -WhatIf
        $result | Should -Not -BeNullOrEmpty
    }

    It 'should not make the HTTP request when making POST requests and WhatIf is true' {
        Get-BMVariable -Session $script:session | Remove-BMVariable -Session $script:session
        $variable = @{
                        'Variable_Name' = 'Fubar';
                        'Variable_Value' = ('Snafu' | ConvertTo-BMNativeApiByteValue);
                        'ValueType_Code' = 'string';
                        'Sensitive_Indicator' = 'False';
                        'EvaluateVariables_Indicator' = 'False';
                    }
        Invoke-BMNativeApiMethod -Session $script:session -Name 'Variables_CreateOrUpdateVariable' -Method Post -Parameter $variable
        $variable['Variable_Value'] = 'FizzBuzz'
        Invoke-BMNativeApiMethod -Session $script:session -Name 'Variables_CreateOrUpdateVariable' -Method Post -Parameter $variable -WhatIf
        $result = 'Fubar' | Get-BMVariable -Session $script:session -ValueOnly
        $result | Should -Be 'Snafu'
    }
}
