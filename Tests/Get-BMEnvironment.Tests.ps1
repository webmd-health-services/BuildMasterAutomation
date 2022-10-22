
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:environments = $null

    function GivenEnvironment
    {
        param(
            [Parameter(Mandatory)]
            [string]$Name,

            [Switch]$Disabled
        )

        New-BMEnvironment -Session $script:session -Name $Name -ErrorAction Ignore
        if( $Disabled )
        {
            $Name | Disable-BMEnvironment -Session $script:session
        }
        else
        {
            $Name | Enable-BMEnvironment -Session $script:session
        }
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
            $script:environments | Should -HaveCount $Named.Count
        }
        foreach( $name in $Named )
        {
            $script:environments | Where-Object { $_.Name -eq $name } | Should -Not -BeNullOrEmpty
        }
    }

    function WhenGettingEnvironments
    {
        [CmdletBinding()]
        param(
            [string]$Named,

            [Switch]$Force,

            [Switch]$WhatIf
        )

        $optionalParams = @{ }
        if( $Named )
        {
            $optionalParams['Environment'] = $Named
        }
        if( $Force )
        {
            $optionalParams['Force'] = $true
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
        $Global:Error.Clear()
        # Disable all existing environments.
        Get-BMEnvironment -Session $script:session | Disable-BMEnvironment -Session $script:session
        $script:environments = $null
    }

    It 'should return all active server environments' {
        GivenEnvironment 'One'
        GivenEnvironment 'Two'
        WhenGettingEnvironments
        ThenEnvironmentsReturned 'One','Two'
        ThenNoErrorWritten
    }

    It 'should return all active and inactive server environments' {
        GivenEnvironment 'One'
        WhenGettingEnvironments -Force
        ThenEnvironmentsReturned 'One' -AndInactiveEnvironments
        ThenNoErrorWritten
    }

    It 'should return specific environment by name' {
        GivenEnvironment 'One'
        GivenEnvironment 'Two'
        WhenGettingEnvironments -Named 'One'
        ThenEnvironmentsReturned 'One'
    }

    It 'should return inactive environment by name' {
        GivenEnvironment 'One' -Disabled
        GivenEnvironment 'Two'
        WhenGettingEnvironments -Named 'One'
        ThenEnvironmentsReturned 'One'
    }

    It 'should return only active environments whose name match the wildcard' {
        GivenEnvironment 'One'
        GivenEnvironment 'Onf'
        GivenEnvironment 'Ong' -Disabled
        GivenEnvironment 'Two'
        WhenGettingEnvironments -Named 'On*'
        ThenEnvironmentsReturned 'One','Onf'
    }

    It 'should return active and inactive environments whose name match the wildcard' {
        GivenEnvironment 'One'
        GivenEnvironment 'Onf'
        GivenEnvironment 'Ong' -Disabled
        GivenEnvironment 'Two'
        WhenGettingEnvironments -Named 'On*' -Force
        ThenEnvironmentsReturned 'One','Onf','Ong'
    }

    It 'should find no environments by name using wildcard' {
        GivenEnvironment 'One'
        GivenEnvironment 'Blah' -Disabled
        WhenGettingEnvironments -Named 'Blah*'
        ThenNoEnvironmentsReturned
        ThenNoErrorWritten
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
