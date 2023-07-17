
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Tests.ps1' -Resolve)

    $script:session = New-BMTestSession

    function ThenRaft
    {
        param(
            [Parameter(Mandatory)]
            [String] $Named,

            [Parameter(Mandatory)]
            [switch] $Exists,

            [hashtable] $HasPropertyValues
        )

        $raft = Get-BMRaft -Session $script:session -Raft $Named
        $raft | Should -Not -BeNullOrEmpty

        if ($HasPropertyValues)
        {
            foreach ($propertyName in $HasPropertyValues.Keys)
            {
                $raft |
                    Get-Member -Name $propertyName |
                    Should -Not -BeNullOrEmpty -Because "missing property $($propertyName)"
                $raft.$propertyName | Should -Be $HasPropertyValues[$propertyName] -Because $propertyName
            }
        }
    }
}

Describe 'Set-BMRaft' {
    BeforeEach {
        $Global:Error.Clear()
        Get-BMRaft -Session $script:session |
            Where-Object 'Raft_Name' -NE 'Default' |
            Remove-BMRaft -Session $script:session
        Get-BMRaft -Session $script:session | Should -HaveCount 1
    }

    It 'should create raft' {
        Set-BMRaft -Session $script:session -Raft 'by raft string'
        ThenRaft 'by raft string' -Exists
    }

    It 'should create raft by piping in raft' {
        'by piping raft string' | Set-BMRaft -Session $script:session
        ThenRaft 'by piping raft string' -Exists
    }

    It 'should set all raft properties' {
        $fsRaftConfig =
            '<Inedo.Extensions.RaftRepositories.DirectoryRaftRepository2 Assembly="Inedo.SDK">' +
                '<Properties RepositoryPath="C:\ProgramData\BuildMaster\Rafts\FileSystemRaft" ReadOnly="False" />' +
            '</Inedo.Extensions.RaftRepositories.DirectoryRaftRepository2>'

        Set-BMRaft -Session $script:session `
                   -Raft 'all properties raft' `
                   -Configuration $fsRaftConfig
        ThenRaft 'all properties raft' `
                 -Exists `
                 -HasPropertyValues @{
                        Raft_Configuration = $fsRaftConfig;
                    }
    }

    It 'should update all raft properties' {
        $fsRaftConfig =
            '<Inedo.Extensions.RaftRepositories.DirectoryRaftRepository2 Assembly="Inedo.SDK">' +
                '<Properties RepositoryPath="C:\ProgramData\BuildMaster\Rafts\FileSystemRaft" ReadOnly="False" />' +
            '</Inedo.Extensions.RaftRepositories.DirectoryRaftRepository2>'

        $raft = Set-BMRaft -Session $script:session `
                           -Raft 'update properties raft' `
                           -Configuration $fsRaftConfig `
                           -PassThru

        $fsRaftConfig = $fsRaftConfig -replace '\bFileSystemRaft\b', '\bFileSystemRaft2\b'
        $raft | Set-BMRaft -Session $script:session -Configuration $fsRaftConfig

        ThenRaft 'update properties raft' `
                 -Exists `
                 -HasPropertyValues @{
                        Raft_Configuration = $fsRaftConfig;
                    }
    }

    # So, PowerShell sets all [String] function parameters to an empty string if not passed. This ends up sending an
    # empty string to BuildMaster for a raft's configuration if the user doesn't set one. BuildMaster then sets the
    # configuration to an empty string, which results in a mis-configured raft that gives an error in the UI. This test
    # exists to ensure we're sending no configuration value when the Configuration parameter is omitted.
    It 'should omit configuration if not passed' {
        Mock -Command 'Invoke-BMNativeApiMethod' `
             -ModuleName 'BuildMasterAutomation' `
             -ParameterFilter { $Name -eq 'Rafts_CreateOrUpdateRaft' }
        Set-BMRaft -Session $script:session -Raft 'configuration omitted raft'
        Assert-MockCalled -CommandName 'Invoke-BMNativeApiMethod' `
                          -ModuleName 'BuildMasterAutomation' `
                          -ParameterFilter { $null -eq $Parameter['Raft_Configuration'] | Should -BeTrue ; $true }
    }
}