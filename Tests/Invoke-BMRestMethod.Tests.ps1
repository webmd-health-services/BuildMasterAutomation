
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
}

Describe 'Invoke-BMRestMethod' {
    It 'should always make GET requests' {
        Invoke-BMRestMethod -Session $script:session -Name 'variables/global/Fubar' -Method Put -Body 'Snafu'
        $result = Invoke-BMRestMethod -Session $script:session -Name 'variables/global' -WhatIf
        $result | Should -Not -BeNullOrEmpty
    }

    It 'should not making Put requests in WhatIf mode' {
        Invoke-BMRestMethod -Session $script:session -Name 'variables/global/Fubar' -Method Put -Body 'Snafu'
        Invoke-BMRestMethod -Session $script:session `
                            -Name 'variables/global/Fubar' `
                            -Method Put `
                            -Body 'FizzBuzz' `
                            -WhatIf
        $result = Invoke-BMRestMethod -Session $script:session -Name 'variables/global/Fubar'
        $result | Should -Be 'Snafu'
    }
}
