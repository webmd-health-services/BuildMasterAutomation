
function Set-BMRelease
{
    <#
    .SYNOPSIS
    Creates or updates a release in BuildMaster.

    .DESCRIPTION
    The `Set-BMRelease` function creates or updates a release in BuildMaster. If a release doesn't exist, it is created. If it does exists, its name, number, and pipeline are updated.
    

    .EXAMPLE
    
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that represents what BuildMaster instance to connect to and what API key to use. Use `New-BMSession` to create a session object.
        $Session,

        [Parameter(Mandatory=$true,ParameterSetName='Update')]
        [object]
        # The release to update. Can be:
        #
        # * The release's name.
        # * The release's ID.
        # * An release object with either a `Release_Id` or `Release_Name` property that represent the application's ID and name, respectively.
        $Release,

        [int]
        # The ID of the release's new pipeline.
        $PipelineID,

        [string]
        # The new name of the release.
        $Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $bmRelease = Get-BMRelease -Session $Session -Release $Release
        if( -not $bmRelease )
        {
            Write-Error -Message ('Release "{0}" does not exist.' -f $Release)
            return
        }

        if( -not $PipelineID )
        {
            $PipelineID = $bmRelease.PipelineId
        }

        if( -not $Name )
        {
            $Name = $bmRelease.name
        }

        $parameter = @{ 
                        Application_Id = $bmRelease.ApplicationId;
                        Release_Number = $bmRelease.number;
                        Pipeline_Id = $PipelineID;
                        Release_Name = $Name;
                     }
        Invoke-BMNativeApiMethod -Session $Session -Name 'Releases_CreateOrUpdateRelease' -Method Post -Parameter $parameter | Out-Null

        Get-BMRelease -Session $Session -Release $bmRelease
    }
}