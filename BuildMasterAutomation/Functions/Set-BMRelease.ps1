
function Set-BMRelease
{
    <#
    .SYNOPSIS
    Updates a release in BuildMaster.

    .DESCRIPTION
    The `Set-BMRelease` function creates a BuildMaster release or updates an existing release. Pass the release's
    pipeline name or a pipeline object to the `Pipeline` object. Pass the release's name to the `Name` parameter.

    This function uses the BuildMaster native API endpoint "Releases_CreateOrUpdateRelease".

    If any parameter isn't passed, and the release exists, the respective properties on the release won't be updated.

    .EXAMPLE
    Set-BMRelease -Session $session -Release $release -Pipeline 'My Pipeline' -Name 'My New Name'

    Demonstrates how to update the pipeline and name of a release.
    #>
    [CmdletBinding()]
    param(
        # The session to BuildMaster. Use the `New-BMSession` object to create the session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The release to update. Pass the release's id, name, or a release object.
        [Parameter(Mandatory, ParameterSetName='Update')]
        [Object] $Release,

        # The release's pipeline.
        [Alias('PipelineID')]
        [Object] $Pipeline,

        # The release's name. If the release exists, its name will be changed to this value.
        [String] $Name
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

        $pipelineName = $bmRelease.pipelineName
        if ($Pipeline)
        {
            $pipelineName = $Pipeline.RaftItem_Name
        }

        if( -not $Name )
        {
            $Name = $bmRelease.name
        }

        $parameter = @{
                        Application_Id = $bmRelease.ApplicationId;
                        Release_Number = $bmRelease.number;
                        Pipeline_Name = $pipelineName;
                        Release_Name = $Name;
                     }
        Invoke-BMNativeApiMethod -Session $Session -Name 'Releases_CreateOrUpdateRelease' -Method Post -Parameter $parameter | Out-Null

        Get-BMRelease -Session $Session -Release $bmRelease
    }
}