
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:environments = $null
    $script:testName = ''

    function GivenEnvironment
    {
        param(
            [Parameter(Mandatory)]
            [string]$Name,

            [Switch]$Disabled
        )

        New-BMEnvironment -Session $script:session -Name "${script:testName}_${Name}" -ErrorAction Ignore
    }

    function ThenNoEnvironmentsReturned
    {
        $script:environments | Should -BeNullOrEmpty
    }

    function ThenEnvironmentsReturned
    {
        param(
            [Parameter(Mandatory)]
            [string[]]$Named,

            [Switch]$AndInactiveEnvironments
        )

        if( $AndInactiveEnvironments )
        {
            $script:environments | Should -Not -BeNullOrEmpty
        }
        else
        {
            ($script:environments | Measure-Object).Count | Should -BeGreaterOrEqual $Named.Count
        }

        foreach( $name in $Named )
        {
            $script:environments | Where-Object 'Name' -EQ "${script:testName}_${name}" | Should -Not -BeNullOrEmpty
        }
    }

    function WhenGettingEnvironments
    {
        [CmdletBinding()]
        param(
            [string]$Named,

            [Switch]$WhatIf
        )

        $optionalParams = @{ }
        if( $Named )
        {
            $optionalParams['Environment'] = "${script:testName}_${Named}"
        }

        $originalWhatIf = $Global:WhatIfPreference
        if( $WhatIf )
        {
            $Global:WhatIfPreference = $true
        }
        try
        {
            $script:environments = Get-BMEnvironment -Session $script:session @optionalParams
        }
        finally
        {
            $Global:WhatIfPreference = $originalWhatIf
        }
    }
}

Describe 'Get-BMEnvironment' {
    BeforeEach {
        $script:environments = $null
        $script:testName = New-BMTestObjectName -Separator '_'
        $Global:Error.Clear()
    }

    It 'should return all environments' {
        GivenEnvironment 'One'
        GivenEnvironment 'Two'
        WhenGettingEnvironments
        ThenEnvironmentsReturned 'One','Two'
        ThenNoErrorWritten
    }

    It 'should return specific environment by name' {
        GivenEnvironment 'One'
        GivenEnvironment 'Two'
        WhenGettingEnvironments -Named 'One'
        ThenEnvironmentsReturned 'One'
    }

    It 'should not find non-existent environment' {
        GivenEnvironment 'One'
        WhenGettingEnvironments -Named ('Blah{0}' -f [IO.Path]::GetRandomFileName()) -ErrorAction SilentlyContinue
        ThenNoEnvironmentsReturned
        ThenError 'does\ not\ exist'
    }

    It 'should ignore errors' {
        GivenEnvironment 'One'
        WhenGettingEnvironments -Named ('Blah{0}' -f [IO.Path]::GetRandomFileName()) -ErrorAction Ignore
        ThenNoEnvironmentsReturned
        ThenNoErrorWritten
    }

    It 'should ignore WhatIf' {
        GivenEnvironment 'One'
        WhenGettingEnvironments 'One' -WhatIf
        ThenEnvironmentsReturned 'One'
        ThenNoErrorWritten
    }
}
