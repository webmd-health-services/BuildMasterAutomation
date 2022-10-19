
function Set-BMRaftItem
{
    <#
    .SYNOPSIS
    Creates or updates a raft item in BuildMaster.

    .DESCRIPTION
    The `Set-BMRaftItem` function creates or updates a raft item in BuildMaster. Pass the raft item's name to the
    `Name` parameter. Pass the raft item's raft id or a raft object to the `Raft` parameter. Pass the object's
    type to the `TypeCode` parameter. The raft item will be created if it doesn't exist, or updated if it does.

    To assign the raft item to a specific application, pass the application's id, name or an application object to the
    `Application` parameter.

    Pass the raft item's content to the `Content` parameter.

    Pass the username of the user creating/updating the raft item to the `UserName` parameter. The default username is
    `DOMAIN\UserName` if the current computer is in a Microsoft domain, `UserName@MachineName` otherwise.

    If you want the created/updated raft item's object to be returned, use the `PassThru` switch.

    When creating scripts, the name of the raft item should end with an extension for the type of script it is, e.g.
    `.ps1` for PowerShell scripts, `.sh` for shell scripts, etc.

    Parameters not passed will not be sent to BuildMaster, and typically BuildMaster leaves those values as-is. Any
    parameter that you pass will get sent to BuildMaster and the respective raft item properties will be updated.

    .EXAMPLE
    Set-BMRaftItem -Session $session -Raft $raft -TypeCode Pipeline -Name 'Pipeline'

    Demonstrates how to use Set-BMRaftItem. In this example, an empty, global pipeline will be created in the raft
    represented by the `$raft` object.

    .EXAMPLE
    Set-BMRaftItem -Session $session -Raft $raft -TypeCode Module -Name 'Module' -Application $app -Content $otterScript

    Demonstrates how to use Set-BMRaftItem. In this example, an module will be created/updated for the application
    represented by the `$app` object with the content in the `$otterScript` variable.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use `New-BMSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The raft where the raft item should be saved. Pass the raft id, name or a raft object.
        [Parameter(Mandatory)]
        [Object] $Raft,

        # The type of the raft item. Valid values are:
        #
        # * Module (for creating OtterScript modules)
        # * Script (for creating PowerShell, batch, or shell scripts; make sure the raft item's name ends with the
        # extension for that script type)
        # * DeploymentPlan (for creating a deployment plan)
        # * Pipeline (for creating a pipeline; use `Set-BMPipeline` instead)
        [Parameter(Mandatory)]
        [BMRaftItemTypeCode] $TypeCode,

        # The name of the raft item.
        #
        # If the raft item is a script, the name must end with the extension of the script type, e.g. `.ps1` for
        # PowerShell scripts, `.sh` for shell scripts, etc.
        [Parameter(Mandatory)]
        [String] $Name,

        # The application the raft item belongs to. Pass the application's id, name, or an application object.
        [Object] $Application,

        # The content of the raft item.
        [String] $Content,

        # The username of the individual who is creating/updating the raft item.
        [String] $UserName,

        # If set, will return an object representing the created/update raft item.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( -not $UserName )
    {
        $UserName = [Environment]::UserName
        if ([Environment]::UserDomainName)
        {
            $UserName = "$([Environment]::UserDomainName)\$($UserName)"
        }
        else
        {
            $UserName = "$($UserName)@$([Environment]::MachineName)"
        }
    }

    $contentBytes = $Content | ConvertTo-BMNativeApiByteValue
    $raftParams = @{
            RaftItem_Name = $Name;
            RaftItemType_Code = $TypeCode;
            ModifiedOn_Date = [DateTimeOffset]::Now;
            ModifiedBy_User_Name = $UserName;
        } |
        Add-BMObjectParameter -ForNativeApi -PassThru -Name 'Application' -Value $Application |
        Add-BMObjectParameter -ForNativeApi -PassThru -Name 'Raft' -Value $Raft |
        Add-BMParameter -PassThru -Name 'ModifiedBy_User_Name' -Value $UserName |
        Add-BMParameter -PassThru -Name 'Content_Bytes' -Value $contentBytes

    Invoke-BMNativeApiMethod -Session $Session `
                             -Name 'Rafts_CreateOrUpdateRaftItem' `
                             -Parameter $raftParams `
                             -Method Post |
        Out-Null

    if ($PassThru)
    {
        Get-BMRaftItem -Session $Session -Raft $Raft -Name $Name -Application $Application -TypeCode $TypeCode
    }
}