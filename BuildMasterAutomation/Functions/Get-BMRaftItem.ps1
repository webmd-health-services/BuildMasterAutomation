
function Get-BMRaftItem
{
    <#
    .SYNOPSIS
    Gets raft items from BuildMaster.

    .DESCRIPTION
    The `Get-RaftItem` function gets all the raft items in a specific raft. Pass the raft ID or object to the `Raft`
    parameter. By default, all raft items in that raft are returned. To return an item with a specific name, pass the
    name to the `Name` parameter (wildcards accepted). To get only raft items used by a specific application, pass the
    application id, name, or object to the `Application` parameter. To get a specific type of raft item, pass the type
    to the `TypeCode` parameter.

    If multiple arguments are passed among the `Name`, `Application`, and `TypeCode` parameters, the `Get-BMRaftItem`
    function returns only raft items that meets *all* search criteria.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Raft $raftId

    Demonstrates how to get all the items from a specific raft.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Raft $raftId -Name '*yolo*'

    Demonstrates how to get raft items from a specific raft whose name matches a specific wildcard pattern. In this
    case, all raft items whose names match `*yolo*` will be returned.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Raft $raftId -Application $appOrIdOrName

    Demonstrates how to get raft items from a specific raft used by a specific application. You can pass an application
    id, name, or object to the `-Application` parameter.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Raft $raftId -TypeCode Pipeline

    Demonstrates how to get raft items from a specific raft with a specific type. In this case, all pipeline raft items
    are returned.
    #>
    [CmdletBinding()]
    param(
        # A session object to the BuildMaster instance to use. Use the `New-BMSession` function to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The raft id, name, or object whose items to return.
        [Parameter(Mandatory)]
        [Object] $Raft,

        # The name of the item to get. Supports wildcards.
        [String] $Name,

        # The application id, name or object whose items to get.
        [Object] $Application,

        # The raft item types to return.
        [BMRaftItemTypeCode] $TypeCode
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $WhatIfPreference = $false # Gets items, but the API requires a POST.

    $getArgs = @{}

    $getArgs |
        Add-BMObjectParameter -Name 'Raft' -Value $Raft -ForNativeApi -PassThru |
        Add-BMObjectParameter -Name 'Application' -Value $Application -ForNativeApi -PassThru |
        Add-BMParameter -Name 'RaftItemType_Code' -Value ([int]$TypeCode)

    $searching = [wildcardpattern]::ContainsWildcardCharacters($Name)
    if ($Name -and -not $searching)
    {
        $getArgs | Add-BMParameter -Name 'RaftItem_Name' -Value $Name
    }

    $raftItems = $null
    Invoke-BMNativeApiMethod -Session $Session -Name 'Rafts_GetRaftItems' -Parameter $getArgs -Method Post |
        Where-Object {
            if (-not $Name -or -not $searching)
            {
                return $true
            }

            return $_.RaftItem_Name -like $Name
        } |
        Tee-Object -Variable 'raftItems' |
        Add-PSTypeName -RaftItem |
        Add-Member -Name 'Type' -MemberType ScriptProperty -Value {
                switch ($this.RaftItemType_Code)
                {
                    3 { return 'Module' }
                    4 { return 'Script' }
                    6 { return 'DeploymentPlan' }
                    8 { return 'Pipeline' }
                    default { return $this.RaftItemType_Code }
                }
            } -PassThru |
        Add-Member -Name 'Content' -MemberType ScriptProperty -Value {
                $this.Content_Bytes | ConvertFrom-BMNativeApiByteValue
            } -PassThru

    if ($Name -and -not $searching -and -not $raftItems)
    {
        $msg = "$($TypeCode | Get-BMRaftTypeDisplayName) ""$($Name)"" doesn't exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
    }
}