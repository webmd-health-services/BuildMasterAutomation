
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

        New-BMPipeline -Session $script:session -Name $Name -Application $ForApplication
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
            $ForPipeline,
            [Switch]$WhatIf
        )

        $optionalParams = @{ }
        if( $Name )
        {
            $optionalParams['Name'] = $Name
        }

        if( $ForApplication )
        {
            $optionalParams['ApplicationID'] = $ForApplication
        }

        if( $ForPipeline )
        {
            $optionalParams['ID'] = $ForPipeline
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
        Invoke-BMNativeApiMethod -Session $script:session -Name 'Pipelines_GetPipelines' |
            ForEach-Object {
                Invoke-BMNativeApiMethod -Session $script:session `
                                         -Name 'Pipelines_DeletePipeline' `
                                         -Parameter @{ Pipeline_Id = $_.Pipeline_Id } `
                                         -Method Post
            }

        Get-BMApplication -Session $script:session |
            ForEach-Object {
                Invoke-BMNativeApiMethod -Session $script:session `
                                         -Name 'Applications_PurgeApplicationData' `
                                         -Parameter @{ Application_Id = $_.Application_Id } `
                                         -Method Post
            }

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

    It 'should return pipeline by its id' {
        $p = GivenPipeline 'One'
        GivenPipeline 'Two'
        WhenGettingPipeline -ForPipeline $p.Pipeline_Id
        ThenReturned 'One'
    }

    It 'should still return pipelines when WhatIf is true' {
        $p = GivenPipeline 'One'
        WhenGettingPipeline -ForPipeline $p.Pipeline_Id -WhatIf
        ThenReturned 'One'
    }
}