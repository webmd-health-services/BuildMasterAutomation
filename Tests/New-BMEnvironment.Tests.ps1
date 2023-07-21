
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    function GivenEnvironment
    {
        param(
            [Parameter(Mandatory)]
            [string[]]$Named,

            [Switch]$Disabled
        )

        foreach( $name in $Named )
        {
            New-BMEnvironment -Session $script:session -Name $name -ErrorAction Ignore
        }
    }

    function New-EnvironmentName
    {
        return 'NewEnvironment{0}' -f ([IO.Path]::GetRandomFileName() -replace '\.','')
    }

    function ThenEnvironmentExists
    {
        param(
            [Parameter(Mandatory)]
            [String]$Named,

            [string]$WithParent
        )

        $environment = $Named | Get-BMEnvironment -Session $script:session

        $environment | Should -Not -BeNullOrEmpty -Because """${Named}"" environment should exist"

        if( $WithParent )
        {
            $environment.parentName | Should -Be $WithParent
        }
        else
        {
            $environment.parentName | Should -BeNullOrEmpty
        }
    }

    function ThenEnvironmentDoesNotExist
    {
        param(
            [Parameter(Mandatory)]
            [string]$Named
        )

        $Named | Get-BMEnvironment -Session $script:session -ErrorAction Ignore | Should -BeNullOrEmpty
    }

    function WhenCreatingEnvironment
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String]$Named,

            [switch]$WhatIf,

            [switch]$Inactive,

            [string]$WithParent
        )

        $optionalParams = @{
                        }
        if( $WhatIf )
        {
            $optionalParams['WhatIf'] = $true
        }

        if( $PSBoundParameters.ContainsKey('Inactive') )
        {
            $optionalParams['Inactive'] = $Inactive
        }

        if( $WithParent )
        {
            $optionalParams['ParentName'] = $WithParent
        }

        $result = New-BMEnvironment -Session $script:session -Name $Named @optionalParams
        $result | Should -BeNullOrEmpty
    }
}

Describe 'New-BMEnvironment' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should create environment' {
        $name = New-EnvironmentName
        WhenCreatingEnvironment -Named $name
        ThenNoErrorWritten
        ThenEnvironmentExists -Named $name
    }

    It 'should fail creating duplicate environment' {
        GivenEnvironment -Named 'Fubar'
        WhenCreatingEnvironment -Named 'Fubar' -ErrorAction SilentlyContinue
        ThenError 'already\ exists'
        ThenEnvironmentExists -Named 'Fubar'
    }

    It 'should reject <_> from end of environment name' -TestCases @('_', '-') {
        $badChar = $_
        $name = 'Fubar{0}' -f $badChar
        { WhenCreatingEnvironment -Named $name } | Should -Throw
        ThenError 'does\ not\ match'
        ThenEnvironmentDoesNotExist -Named $name
    }

    It 'should allow _ and - in environment name ' {
        $name = 'Fubar_-Snafu{0}' -f ([IO.Path]::GetRandomFileName() -replace '\.','')
        WhenCreatingEnvironment -Named $name
        ThenNoErrorWritten
        ThenEnvironmentExists -Named $name
    }

    It 'should allow environment with single letter name' {
        $name = 'F'
        WhenCreatingEnvironment -Named $name -ErrorAction SilentlyContinue
        # Environments can't be deleted so this environment may exist from previous test runs. We just need to make sure the validation passed.
        $Global:Error | Should -Not -Match 'does\ not\ match'
    }

    It 'should reject environment names that are too long' {
        $name = 'F' * 51
        { WhenCreatingEnvironment -Named $name } | Should -Throw
        ThenError 'is\ too\ long'
        ThenEnvironmentDoesNotExist -Named $name
    }

    It 'should support WhatIf' {
        $name = New-EnvironmentName
        WhenCreatingEnvironment -Named $name -WhatIf
        ThenNoErrorWritten
        ThenEnvironmentDoesNotExist -Named $name
    }

    It 'should set the parent environment' {
        GivenEnvironment 'parent'
        $name = New-EnvironmentName
        WhenCreatingEnvironment $name -WithParent 'parent'
        ThenNoErrorWritten
        ThenEnvironmentExists $name -WithParent 'parent'
    }
}
