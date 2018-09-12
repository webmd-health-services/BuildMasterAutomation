
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession

Describe 'Invoke-BMRestMethod.when using WhatIf switch and GET HTTP method' {
    Invoke-BMRestMethod -Session $session -Name 'variables/global/Fubar' -Method Put -Body 'Snafu'
    $result = Invoke-BMRestMethod -Session $session -Name 'variables/global' -WhatIf
    It ('should return a result') {
        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-BMRestMethod.when using WhatIf switch and POST HTTP method' {
    Invoke-BMRestMethod -Session $session -Name 'variables/global/Fubar' -Method Put -Body 'Snafu'
    Invoke-BMRestMethod -Session $session -Name 'variables/global/Fubar' -Method Put -Body 'FizzBuzz' -WhatIf
    $result = Invoke-BMRestMethod -Session $session -Name 'variables/global/Fubar' 
    It ('should not make HTTP call') {
        $result | Should -Be 'Snafu'
    }
}
