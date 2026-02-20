
function Get-BMRaftItem
{
    <#
    .SYNOPSIS
    Gets raft items from BuildMaster.

    .DESCRIPTION
    The `Get-RaftItem` function gets all raft items in all rafts, in a specific raft, or in a specific application. By
    default, it gets all raft items in all rafts. To get all items in a specific raft, pass the raft's ID, name, or
    object to the `Raft` parameter. To get an application's raft items, pass the application's ID, name, or object to
    the `Application` parameter.

    To get a specific ***global*** raft item (i.e. a raft item not part of an application), pass the raft item's ID,
    name, or object to the `RaftItem` parameter.

    To get a raft item that is in an application, pass the raft item's ID, name, or object to the `RaftItem` parameter.
    When passing the raft item's ID or name, you ***must*** also pass the ID, name, or objct of the application to which
    it belongs to the `Application` parameter.

    When getting a raft item by name, wildcards are supported.

    You can also filter raft items by type with the `TypeCode` parameter.

    If getting a raft by name or ID, the function writes an error if the item doesn't exist.

    Uses the BuildMaster native API.

    .EXAMPLE
    Get-BMRaftItem -Session $session

    Demonstrates how to get all global raft items, i.e. raft items not part of any application.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Raft $raftID

    Demonstrates how to get all the items from a specific raft. In this case, all raft items in the raft with ID
    `$raftID` not part of an application are returned.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Name '*yolo*'

    Demonstrates how to get global raft items whose name matches a specific wildcard pattern. In this case, all raft
    items across rafts whose names match `*yolo*` will be returned. No raft items in applications are searched.

    .EXAMPLE
    Get-BMRaftItem -Session $session -Application $appOrIdOrName

    Demonstrates how to get an application's raft items. You can pass an application ID, name or object.

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

        # The ID, name, or object of the raft whose items to return.
        [Object] $Raft,

        # The specific raft item to get. Pass the raft name (wildcards supported), ID, or object. When passing an ID
        # for a raft item in an application, you must *also* pass the application ID, name, or object to the
        # `Application` parameter.
        [Parameter(ValueFromPipeline)]
        [Object] $RaftItem,

        # The ID, name, or object of the application whose raft items to get.
        #
        # When getting a raft item by ID and that raft item is part of an application, you must pass this parameter to
        # return that raft item.
        [Object] $Application,

        # The raft item types to return.
        [BMRaftItemTypeCode] $TypeCode
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $WhatIfPreference = $false # Gets items, but the API requires a POST.

        $stopProcessing = $false

        # BuildMaster's API requires a raft ID at minimum, so use the one provided by the user or search all
        # rafts.
        $getRaftArgs = @{}
        if ($Raft)
        {
            $getRaftArgs['Raft'] = $Raft
        }

        $rafts = Get-BMRaft -Session $Session @getRaftArgs
        if (-not $rafts)
        {
            $stopProcessing = $true
        }

        if ($Application)
        {
            $Application = Get-BMApplication -Session $Session -Application $Application
            if (-not $Application)
            {
                $stopProcessing = $true
            }
        }

        $filteringByTypeCode = $PSBoundParameters.ContainsKey('TypeCode')
    }

    process
    {
        if ($stopProcessing)
        {
            return
        }

        $gettingByID = $false
        $gettingByName = $false
        $searching = $false

        if ($RaftItem)
        {
            # The native API doesn't support getting raft items by ID so we have to get them all and filter ourselves.
            $raftItemID = $RaftItem | Get-BMObjectID -ObjectTypeName 'RaftItem' -ErrorAction Ignore
            $gettingByID = $null -ne $raftItemID

            $raftItemName = $RaftItem | Get-BMOBjectName -ObjectTypeName 'RaftItem' -ErrorAction Ignore
            $gettingByName = $null -ne $raftItemName

            $searching = [wildcardpattern]::ContainsWildcardCharacters($raftItemName)

            if ($searching)
            {
                $gettingByID = $gettingByName = $false
            }

            if (-not $Application)
            {
                $isAppSpecific = (($RaftItem | Get-Member 'Application_Id') -and $RaftItem.Application_Id) -or `
                                 (($RaftItem | Get-Member 'Application_Name') -and $RaftItem.Application_Name)

                # If the item is scoped to an application, and the Application parameter doesn't have a value, get the
                # application.
                if ($isAppSpecific)
                {
                    $fauxApp = $RaftItem | Select-Object -Property 'Application_*'
                    $Application = Get-BMApplication -Session $Session -Application $fauxApp
                    if (-not $Application)
                    {
                        return
                    }
                }
            }
        }

        $raftItems = $null
        & {
                foreach ($currentRaft in $rafts)
                {
                    $getArgs =
                        @{} | Add-BMObjectParameter -Name 'Raft' -Value $currentRaft -ForNativeApi -AsID -PassThru

                    if ($filteringByTypeCode)
                    {
                        $getArgs | Add-BMParameter -Name 'RaftItemType_Code' -Value $TypeCode
                    }

                    if ($Application)
                    {
                        $getArgs['Application_Id'] = $Application.Application_Id
                    }

                    if ($gettingByID)
                    {
                        $getArgs['RaftItem_Id'] = $raftItemID
                    }
                    elseif ($gettingByName)
                    {
                        $getArgs['RaftItem_Name'] = $raftItemName
                    }

                    Invoke-BMNativeApiMethod -Session $Session `
                                             -Name 'Rafts_GetRaftItems' `
                                             -Method Post `
                                             -Parameter $getArgs
                }
            } |
            Where-Object {
                # Apparently, BuildMaster doesn't filter by raft item ID on the server.
                if ($gettingByID)
                {
                    return $_.RaftItem_Id -eq $raftItemID
                }

                if ($searching)
                {
                    $return = $_.RaftItem_Name -like $raftItemName
                    Write-Debug "  $('{0,-5}' -f $return)    $($_.RaftItem_Name)  -like  ${raftItemName}"
                    return $return
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
            if (-not $typeCodeName)
            {
                $typeCodeName = 'Item'
            }

            $nameMsg = """$($RaftItem | Get-BMObjectName -ObjectTypeName 'RaftItem')"""
            if ($RaftItem | Test-BMID)
            {
                $nameMsg = $RaftItem
            }

            $msg = "${typeCodeName} ${nameMsg}$($appMsg) does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
    }
}