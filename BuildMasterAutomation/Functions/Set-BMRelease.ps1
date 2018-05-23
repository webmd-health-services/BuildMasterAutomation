
function Set-BMRelease
{
    <#
    .SYNOPSIS
    Updates a release's pipeline or name.

    .DESCRIPTION
    The `Set-BMRelease` function updates a release's pipeline or name. To change a release's pipeline, pass the pipeline's ID to the `PipelineID` parameter. To change the pipeline's name, pass the new name to the `Name` parameter. 
    
    This function uses the BuildMaster native API endpoint "Releases_CreateOrUpdateRelease".

    Pass the release you want to update to the `Release` parameter. You may pass the release's ID (as an integer), the release's number, or a release object as returned by the `Get-BMRelease` function.

    .EXAMPLE
    Set-BMRelease -Release $release -PipelineID 45 -Name 'My New Name'

    Demonstrates how to update the pipeline and name of a release.
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
        # * The release's number.
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