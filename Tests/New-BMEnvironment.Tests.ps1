
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession

function Init
{
    $Global:Error.Clear()
    Get-BMEnvironment -Session $session | Disable-BMEnvironment -Session $session
}

function GivenEnvironment
{
    param(
        [Parameter(Mandatory)]
        [string[]]$Named,

        [Switch]$Disabled
    )

    foreach( $name in $Named )
    {
        New-BMEnvironment -Session $session -Name $name -ErrorAction Ignore
        if( $Disabled )
        {
            Disable-BMEnvironment -Session $session -Name $Name
        }
        else
        {
            Enable-BMEnvironment -Session $session -Name $name
        }
    }
}

function New-EnvironmentName
{
    return 'NewEnvironment{0}' -f ([IO.Path]::GetRandomFileName() -replace '\.','')
}

function ThenError
{
    param(
        [Parameter(Mandatory)]
        [string]$Matches
    )

    $Global:Error | Should -Match $Matches
}

function ThenNoErrorWritten
{
    $Global:Error | Should -BeNullOrEmpty
}

function ThenEnvironmentExists
{
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Switch]$Disabled
    )

    $environment = Get-BMEnvironment -Session $session -Name $Named

    $environment | Should -Not -BeNullOrEmpty

    if( $Disabled )
    {
        $environment.active | Should -BeFalse
    }
    else
    {
        $environment.active | Should -BeTrue
    }
}

function ThenEnvironmentDoesNotExist
{
    param(
        [Parameter(Mandatory)]
        [string]$Named
    )

    Get-BMEnvironment -Session $session -Name $Named -ErrorAction Ignore | Should -BeNullOrEmpty
}

function WhenCreatingEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Named,

        [Switch]$WhatIf
    )

    $optionalParams = @{
                      }
    if( $WhatIf )
    {
        $optionalParams['WhatIf'] = $true
    }

    $result = New-BMEnvironment -Session $session -Name $Named @optionalParams
    $result | Should -BeNullOrEmpty
}

Describe 'New-BMEnvironment.when creating a new environment' {
    It ('should not create environment') {
        $name = New-EnvironmentName
        Init
        WhenCreatingEnvironment -Named $name
        ThenNoErrorWritten
        ThenEnvironmentExists -Named $name
    }
}

Describe 'New-BMEnvironment.when environment already exists' {
    It ('should not create environment') {
        Init
        GivenEnvironment -Named 'Fubar'
        WhenCreatingEnvironment -Named 'Fubar' -ErrorAction SilentlyContinue
        ThenError 'already\ exists'
        ThenEnvironmentExists -Named 'Fubar'
    }
}

Describe 'New-BMEnvironment.when environment already exists and is disabled' {
    It ('should not enable environment') {
        Init
        GivenEnvironment -Named 'Fubar' -Disabled
        WhenCreatingEnvironment -Named 'Fubar' -ErrorAction SilentlyContinue
        ThenError 'duplicate\ key'
        ThenEnvironmentExists -Named 'Fubar' -Disabled
    }
}

foreach( $badChar in @( '_', '-' ) )
{
    Describe ('New-BMEnvironment.when name ends with "{0}"' -f $badChar) {
        It ('should not create environment') {
            $name = 'Fubar{0}' -f $badChar
            Init
            { WhenCreatingEnvironment -Named $name } | Should -Throw
            ThenError 'does\ not\ match'
            ThenEnvironmentDoesNotExist -Named $name
        }
    }
    
}

Describe ('New-BMEnvironment.when name contains characters that it shouldn''t end with') {
    It ('should create environment') {
        $name = 'Fubar_-Snafu{0}' -f ([IO.Path]::GetRandomFileName() -replace '\.','')
        Init
        WhenCreatingEnvironment -Named $name
        ThenNoErrorWritten
        ThenEnvironmentExists -Named $name
    }
}

Describe ('New-BMEnvironment.when name contains one letter') {
    It ('should pass validation') {
        $name = 'F'
        Init
        WhenCreatingEnvironment -Named $name -ErrorAction SilentlyContinue
        # Environments can't be deleted so this environment may exist from previous test runs. We just need to make sure the validation passed.
        $Global:Error | Should -Not -Match 'does\ not\ match'
    }
}

Describe ('New-BMEnvironment.when name is too long') {
    It ('should not create environment') {
        $name = 'F' * 51
        Init
        { WhenCreatingEnvironment -Named $name } | Should -Throw
        ThenError 'is\ too\ long'
        ThenEnvironmentDoesNotExist -Named $name
    }
}

Describe 'New-BMEnvironment.when using -WhatIf' {
    It ('should not create the environment') {
        $name = New-EnvironmentName
        Init
        WhenCreatingEnvironment -Named $name -WhatIf
        ThenNoErrorWritten
        ThenEnvironmentDoesNotExist -Named $name
    }
}
