
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    function GivenApp
    {
        [CmdletBinding()]
        param(
            [String] $Named
        )

        New-BMApplication -Session $script:session -Name $Named
    }

    function ThenApp
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String] $Named,

            [Parameter(Mandatory)]
            [switch] $Is,

            [switch] $Not,

            [Parameter(Mandatory)]
            [switch] $Disabled
        )

        $active = $Named | Get-BMApplication -Session $script:session | Select-Object -ExpandProperty 'Active_Indicator'

        if ($Not)
        {
            $active | Should -BeTrue
        }
        else
        {
            $active | Should -BeFalse
        }
    }

    function WhenDisabling
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ParameterSetName='ByParam', Position=0)]
            [Object] $Application,

            [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='ByPiping')]
            [Object] $InputObject,

            [hashtable]$WithArgs = @{}
        )

        process
        {
            if ($PSCmdlet.ParameterSetName -eq 'ByParam')
            {
                Disable-BMApplication -Session $script:session -Application $Application @WithArgs
            }
            else
            {
                $InputObject | Disable-BMApplication -Session $script:session @WithArgs
            }
        }
    }
}

Describe 'Disable-BMApplication' {
    BeforeEach {
        $script:appName = New-BMTestObjectName
        $Global:Error.Clear()
    }

    It 'should disable by piped name' {
        GivenApp -Named $script:appName
        $script:appName | WhenDisabling
        ThenApp $script:appName -Is -Disabled
    }

    It 'should disable by piped id' {
        GivenApp -Named $script:appName
        $script:appName |
            Get-BMApplication -Session $script:session |
            Select-Object -ExpandProperty 'Application_Id' |
            WhenDisabling
        ThenApp $script:appName -Is -Disabled
    }

    It 'should disable by piped application' {
        GivenApp -Named $script:appName
        $script:appName | Get-BMApplication -Session $script:session | WhenDisabling
        ThenApp $script:appName -Is -Disabled
    }

    It 'should disable by name arg' {
        GivenApp -Named $script:appName
        WhenDisabling $script:appName
        ThenApp $script:appName -Is -Disabled
    }

    It 'should disable by id arg' {
        GivenApp -Named $script:appName
        $app =  $script:appName | Get-BMApplication -Session $script:session
        # On Windows PowerShell, is an [int]. Other versions, a [long], so just make sure its only digits.
        $app.Application_Id | Should -Match '^\d+$'
        WhenDisabling $app.Application_Id
        ThenApp $script:appName -Is -Disabled
    }

    It 'should disable by application arg' {
        GivenApp -Named $script:appName
        $app = $script:appName | Get-BMApplication -Session $script:session
        WhenDisabling $app
        ThenApp $script:appName -Is -Disabled
    }

    It 'should validate application exists' {
        $script:appName | WhenDisabling -ErrorAction SilentlyContinue
        ThenError -MatchesPattern "Application ""$($script:appName)"" does not exist."
    }

    It 'should ignore missing application' {
        $script:appName | WhenDisabling -WithArgs @{ ErrorAction = 'Ignore' }
        ThenError -IsEmpty
    }

    It 'should support WhatIf' {
        GivenApp $script:appName
        $script:appName | WhenDisabling -WithArgs @{ WhatIf = $true }
        ThenApp $script:appName -Is -Not -Disabled
    }
}