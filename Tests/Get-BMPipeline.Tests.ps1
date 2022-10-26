
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

AfterAll {
    $script:defaultRaft | Remove-BMRaft -Session $script:session
}

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:result = $null
    $script:defaultRaft =
        "Get-BMPipeline.$([IO.Path]::GetRandomFileName())" | Set-BMRaft -Session $script:session -PassThru
    $script:defaultRaft | Should -Not -BeNullOrEmpty

    function GivenApplication
    {
        param(
            $Name
        )

        $app = Get-BMApplication -Session $script:session -Application $Name -ErrorAction Ignore
        if ($app)
        {
            return $app
        }

        return New-BMApplication -Session $script:session -Name $Name
    }

    function GivenPipeline
    {
        [CmdletBinding(DefaultParameterSetName='Global')]
        param(
            [Parameter(Position=0)]
            $Name,

            [Parameter(ParameterSetName='Application')]
            $ForApplication,

            [Parameter(ParameterSetName='Global')]
            $InRaft = $script:defaultRaft
        )

        $setArgs = @{}
        if ($ForApplication)
        {
            $setArgs['Application'] = $ForApplication
        }
        else
        {
            $setArgs['Raft'] = $InRaft
        }
        Set-BMPipeline -Session $script:session -Name $Name @setArgs
    }

    function ThenReturned
    {
        param(
            [String[]] $Name
        )

        ($script:result | Measure-Object).Count | Should -Be ($Name | Measure-Object).Count
        foreach( $nameItem in $Name )
        {
            $script:result | Where-Object { $_.Pipeline_Name -eq $nameItem } | Should -Not -BeNullOrEmpty
        }
    }

    function WhenGettingPipeline
    {
        param(
            [hashtable] $WithArgs = @{},
            [Switch]$WhatIf
        )

        $originalWhatIf = $WhatIfPreference
        try
        {
            if( $WhatIf )
            {
                $Global:WhatIfPreference = $true
            }

            $script:result = Get-BMPipeline -Session $script:session @WithArgs
        }
        finally
        {
            $Global:WhatIfPreference = $originalWhatIf
        }
    }
}

Describe 'Get-BMPipeline' {
    BeforeEach {
        Get-BMPipeline -Session $session | Remove-BMPipeline -Session $session -PurgeHistory
        Get-BMApplication -Session $session | Remove-BMApplication -Session $session -Force

        $script:result = $null
        $Global:Error.Clear()
    }

    It 'should return all pipelines' {
        GivenPipeline 'One'
        GivenPipeline 'Two'
        WhenGettingPipeline
        ThenReturned 'One','Two'
    }

    It 'should return specific pipeline' {
        GivenPipeline 'One'
        GivenPipeline 'Two'
        WhenGettingPipeline -WithArgs @{ Raft = $script:defaultRaft ; Pipeline = 'One' ; }
        ThenReturned 'One'
    }

    It 'should return pipelines that match a wildcard' {
        GivenPipeline 'OneA'
        GivenPipeline 'OneB'
        GivenPipeline 'Two'
        WhenGettingPipeline -WithArgs @{ Raft = $script:defaultRaft ; Pipeline = 'One*' ; }
        ThenReturned 'OneA','OneB'
    }

    It 'should return an application''s pipelines' {
        $app = GivenApplication 'One'
        GivenPipeline 'One_1' -ForApplication $app.Application_Id
        GivenPipeline 'One_2' -ForApplication $app.Application_Id
        GivenPipeline 'Two'
        WhenGettingPipeline -WithArgs @{ Application = $app.Application_Id ; }
        ThenReturned 'One_1','One_2'
    }

    It 'should still return pipelines when WhatIf is true' {
        GivenPipeline 'One'
        WhenGettingPipeline -WithArgs @{ Pipeline = 'One' ; } -WhatIf
        ThenReturned 'One'
    }

    It 'should return pipelines in a specific raft' {
        $bmRaft = 'get-bmpipeline raft' | Set-BMRaft -Session $script:session -PassThru
        GivenPipeline 'Three' -InRaft $bmRaft
        WhenGettingPipeline -WithArgs @{ Raft = $bmRaft }
        ThenReturned 'Three'
    }
}