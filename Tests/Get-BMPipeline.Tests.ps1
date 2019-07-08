
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

$session = New-BMTestSession 
$result = $null

function GivenApplication
{
    param(
        $Name
    )

    New-BMApplication -Session $session -Name $Name 
}

function GivenPipeline
{
    param(
        $Name,

        $ForApplication
    )

    New-BMPipeline -Session $session -Name $Name -Application $ForApplication
}

function Init
{
    Invoke-BMNativeApiMethod -Session $session -Name 'Pipelines_GetPipelines' |
        ForEach-Object { Invoke-BMNativeApiMethod -Session $session -Name 'Pipelines_DeletePipeline' -Parameter @{ Pipeline_Id = $_.Pipeline_Id } -Method Post }

    Get-BMApplication -Session $session |
        ForEach-Object { Invoke-BMNativeApiMethod -Session $session -Name 'Applications_PurgeApplicationData' -Parameter @{ Application_Id = $_.Application_Id } -Method Post }

    $script:result = $null
}

function ThenReturned
{
    param(
        $Name
    )

    ($result | Measure-Object).Count | Should -Be ($Name | Measure-Object).Count
    foreach( $nameItem in $Name )
    {
        $result | Where-Object { $_.Pipeline_Name -eq $nameItem } | Should -Not -BeNullOrEmpty
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

        $script:result = Get-BMPipeline -Session $session @optionalParams
    }
    finally
    {
        $Global:WhatIfPreference = $originalWhatIf
    }
}

Describe 'Get-BMPipeline.when requesting all pipelines' {
    It 'should return all pipelines' {
        Init
        GivenPipeline 'One'
        GivenPipeline 'Two'
        WhenGettingPipeline
        ThenReturned 'One','Two'
    }
}

Describe 'Get-BMPipeline.when requesting a pipeline by name' {
    It 'should return only that pipeline' {
        Init
        GivenPipeline 'One'
        GivenPipeline 'Two'
        WhenGettingPipeline 'One'
        ThenReturned 'One'
    }
}

Describe 'Get-BMPipeline.when requesting a pipelines using a wildcard' {
    It 'should return pipelines that match' {
        Init
        GivenPipeline 'OneA'
        GivenPipeline 'OneB'
        GivenPipeline 'Two'
        WhenGettingPipeline 'One*'
        ThenReturned 'OneA','OneB'
    }
}

Describe 'Get-BMPipeline.when requesting an application''s pipelines' {
    It 'should return those pipelines' {
        Init
        $app = GivenApplication 'One'
        GivenPipeline 'One_1' -ForApplication $app.Application_Id
        GivenPipeline 'One_2' -ForApplication $app.Application_Id
        GivenPipeline 'Two'
        WhenGettingPipeline -ForApplication $app.Application_Id
        ThenReturned 'One_1','One_2'
    }
}

Describe 'Get-BMPipeline.when requesting a pipeline by ID' {
    It 'should that pipeline' {
        Init
        $p = GivenPipeline 'One'
        GivenPipeline 'Two'
        WhenGettingPipeline -ForPipeline $p.Pipeline_Id
        ThenReturned 'One'
    }
}

Describe 'Get-BMPipeline.when WhatIfPreference is true' {
    It 'should still return pipelines' {
        Init
        $p = GivenPipeline 'One'
        WhenGettingPipeline -ForPipeline $p.Pipeline_Id -WhatIf
        ThenReturned 'One'
    }
}