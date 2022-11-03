
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession
    $script:result = $null

    function GivenApplication
    {
        param(
            $Name
        )

        New-BMApplication -Session $script:session -Name $Name
    }

    function GivenPipeline
    {
        param(
            $Name,

            $ForApplication
        )

        Set-BMPipeline -Session $script:session -Name $Name -Application $ForApplication
    }

    function ThenReturned
    {
        param(
            $Name
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
            $Name,
            $ForApplication,
            [Switch]$WhatIf
        )

        $optionalParams = @{ }
        if( $Name )
        {
            $optionalParams['Name'] = $Name
        }

        if( $ForApplication )
        {
            $optionalParams['Application'] = $ForApplication
        }

        $originalWhatIf = $WhatIfPreference
        try
        {
            if( $WhatIf )
            {
                $Global:WhatIfPreference = $true
            }

            $script:result = Get-BMPipeline -Session $script:session @optionalParams
        }
        finally
        {
            $Global:WhatIfPreference = $originalWhatIf
        }
    }
}

Describe 'Get-BMPipeline' {
    BeforeEach {
        Get-BMPipeline -Session $session | Remove-BMPipeline -Session $session
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
        WhenGettingPipeline 'One'
        ThenReturned 'One'
    }

    It 'should return pipelines that match a wildcard' {
        GivenPipeline 'OneA'
        GivenPipeline 'OneB'
        GivenPipeline 'Two'
        WhenGettingPipeline 'One*'
        ThenReturned 'OneA','OneB'
    }

    It 'should return an application''s pipelines' {
        $app = GivenApplication 'One'
        GivenPipeline 'One_1' -ForApplication $app.Application_Id
        GivenPipeline 'One_2' -ForApplication $app.Application_Id
        GivenPipeline 'Two'
        WhenGettingPipeline -ForApplication $app.Application_Id
        ThenReturned 'One_1','One_2'
    }

    It 'should still return pipelines when WhatIf is true' {
        GivenPipeline 'One'
        WhenGettingPipeline -Name 'One' -WhatIf
        ThenReturned 'One'
    }
}