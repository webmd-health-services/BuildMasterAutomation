
function Get-BMRaftItem
{
    <#
    .SYNOPSIS
    Gets raft items from BuildMaster.

    .DESCRIPTION
    The `Get-RaftItem` function gets all raft items across rafts and applications.

    To get only raft items in a specific raft, pass the raft's id or raft object to the `Raft` parameter.

    To get a specific raft item by its name, pass the name or raft item's object to the `RaftItem` parameter.

    To get raft items assigned to a specific application, pass the application id or application object to the
    `Application` parameter.

    To get raft items for a specific type, pass the type code to the `TypeCode parameter.

    Raft items are only returned if they match all parameters passed.

    Uses the BuildMaster native API.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Raft $raftID

    Demonstrates how to get all the items from a specific raft. In this case, all raft items in the raft with id
    `$raftID` in any or no application are returned.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Name '*yolo*'

    Demonstrates how to get raft items whose name matches a specific wildcard pattern. In this case, all raft items
    across rafts and applications whose names match `*yolo*` will be returned.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Application $appOrIdOrName

    Demonstrates how to get raft items from a specific application. You can pass an application id or object to the
    `-Application` parameter.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Raft $raftID -TypeCode Pipeline

    Demonstrates how to get all raft items of a specific type. In this case, all pipeline raft items across all rafts
    and applications are returned.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Raft $raft -RaftItem 'specific' -Application $app -TypeCode Pipeline

    Demonstrates how to get a specific pipeline. In this case, it will return the pipeline raft item named `specific`
    from the `$raft` raft, assigned to application `$app`.
    #>
    [CmdletBinding()]
    param(
        # A session object to the BuildMaster instance to use. Use the `New-BMSession` function to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The raft id or raft object whose items to return.
        [Object] $Raft,

        # The raft item to get. Pass the raft name (wildcards supported) or raft item object.
        [Parameter(ValueFromPipeline)]
        [Object] $RaftItem,

        # The application id or application object whose items to get.
        [Object] $Application,

        # The raft item types to return.
        [BMRaftItemTypeCode] $TypeCode
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false # Gets items, but the API requires a POST.

        $appFilter = $null
    }

    process
    {
        $getRaftArgs = @{}
        if ($Raft)
        {
            $getRaftArgs['Raft'] = $Raft
        }

        $searching = ($RaftItem | Test-BMName) -and [wildcardpattern]::ContainsWildcardCharacters($RaftItem)

        $raftItems = $null
        & {
                # BuildMaster's API requires a raft ID at minimum, so use the one provided by the user or search all
                # rafts.
                foreach ($currentRaft in (Get-BMRaft -Session $Session @getRaftArgs))
                {
                    $getArgs =
                        @{} | Add-BMObjectParameter -Name 'Raft' -Value $currentRaft -ForNativeApi -AsID -PassThru

                    if ($RaftItem -and -not $searching)
                    {
                        $getArgs | Add-BMObjectParameter -Name 'RaftItem' -Value $RaftItem -AsName -ForNativeApi
                    }

                    if ($PSBoundParameters.ContainsKey('TypeCode'))
                    {
                        $getArgs | Add-BMParameter -Name 'RaftItemType_Code' -Value $TypeCode
                    }

                    if (-not $Application)
                    {
                        # If no Application_Id parameter, BuildMaster's API only returns pipelines that are not
                        # associated with an application.
                        Invoke-BMNativeApiMethod -Session $Session `
                                                 -Name 'Rafts_GetRaftItems' `
                                                 -Method Post `
                                                 -Parameter $getArgs
                    }

                    if ($null -eq $appFilter)
                    {
                        if ($Application)
                        {
                            $appFilter = $Application
                        }
                        else
                        {
                            $appFilter = Get-BMApplication -Session $Session
                        }
                    }

                    # Get all raft items associated with the users application or any application.
                    foreach ($appItem in $appFilter)
                    {
                        $getArgs | Add-BMObjectParameter -Name 'Application' -Value $appItem -ForNativeApi -AsID
                        Invoke-BMNativeApiMethod -Session $Session `
                                                 -Name 'Rafts_GetRaftItems' `
                                                 -Method Post `
                                                 -Parameter $getArgs
                    }
                }
            } |
            Where-Object {
                if ($searching)
                {
                    return $_.RaftItem_Name -like $RaftItem
                }
                return $true
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
                } -PassThru |
            Write-Output


        if ($RaftItem -and -not $searching -and -not $raftItems)
        {
            $appMsg = ''
            if ($Application)
            {
                $appMsg = " in application ""$($Application | Get-BMObjectName -ObjectTypeName 'Application')"""
            }
            $typeCodeName = $TypeCode | Get-BMRaftTypeDisplayName -ErrorAction Ignore
            $msg = "$($typeCodeName) ""$($RaftItem | Get-BMObjectName -ObjectTypeName 'RaftItem')""$($appMsg) " +
                   'does not exist.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}