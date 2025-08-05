
function New-BMBuild
{
    <#
    .SYNOPSIS
    Creates a new build.

    .DESCRIPTION
    The `New-BMBuild` creates a new version/build of an application. In order to deploy the build, it must be assigned
    to an application and a release or a pipeline. To assign the build to a release and the release's application, pass
    the release ID or object to the `Release` parameter and `New-BMBuild` will determine the application based on the
    release.

    You can use the release number to assing a build to a release by passing it to the `ReleaseNumber` parameter. Since
    release numbers can be duplicated between applications, you must also pass the application ID, name, or object to
    the `Application` parameter.

    To assign the build to an application without assigning it to a release, it must be assigned to a pipeline. Pass the
    application ID, name or object to the `Application` parameter and the pipeline name to the `PipelineName` parameter.

    .EXAMPLE
    New-BMBuild -Session $session -Release $release

    Demonstrates how to create a new build in the `$release` release. BuildMaster detects what application based on the
    release (since releases are always tied to applications). Version numbers and build numbers are incremented and
    handled based on the release settings.

    The `$release` parameter can be:

    * A release object with an `id` property.
    * A release ID integer.

    .EXAMPLE
    New-BMBuild -Session $session -ReleaseName '53' -Application $applicatoin

    Demonstrates how to create a new build by using the release's name. Since release names are only unique within an
    application, you must also specify the application via the `Application` parameter.

    .EXAMPLE
    New-BMBuild -Session $session -Release $release -BuildNumber '56.develop' -Variable @{ ProGetPackageName = '17.1.54+developer.deadbee' }

    Demonstrates how to create a release with a specific name, `56.develop`, and with a build-level variable,
    `ProGetPackageName`.

    .EXAMPLE
    New-BMBuild -Session $session -Application $app -PipelineName 'MyPipeline'

    Demonstrates how to create a new build for an application without using releases.
    #>
    [CmdletBinding()]
    param(
        # An object that represents the instance of BuildMaster to connect to. Use the `New-BMSession` function to
        # creates a session object.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The release where the build should be created. Can be:
        #
        # * a release object with an `id` property
        # * the release ID as an integer
        [Parameter(Mandatory, ParameterSetName='ByReleaseID')]
        [Object] $Release,

        # The release number where the build should be created. Release numbers are unique within an application and
        # can be duplicated between applications. If you use this parameter to identify the release, you must also
        # provide a value for the `Application` parameter.
        [Parameter(Mandatory, ParameterSetName='ByReleaseNumber')]
        [String] $ReleaseNumber,

        # The application where build should be created. Can be:
        #
        # * An application object with a `Application_Id`, `id`, `Application_Name`, or `name` properties.
        # * The application ID as an integer.
        # * The application name as a string.
        [Parameter(Mandatory, ParameterSetName='ByReleaseNumber')]
        [Parameter(Mandatory, ParameterSetName='ByPipeline')]
        [Object] $Application,

        # The pipeline to assign the build to.
        [Parameter(Mandatory, ParameterSetName='ByPipeline')]
        [String] $PipelineName,

        # The build number/name. If not provided, BuildMaster generates one based on the release or application
        # settings.
        [String] $BuildNumber,

        # Any build variables to set. Build variables are unique to each build.
        [hashtable] $Variable
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parameters = @{ }

    if ($PSCmdlet.ParameterSetName -eq 'ByReleaseID')
    {
        $parameters | Add-BMObjectParameter -Name 'release' -Value $Release
    }
    else
    {
        $parameters | Add-BMObjectParameter -Name 'application' -Value $Application
        if ($PSCmdlet.ParameterSetName -eq 'ByReleaseNumber')
        {
            $parameters['releaseNumber'] = $ReleaseNumber
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByPipeline')
        {
            $parameters['pipelineName'] = $PipelineName
        }
    }

    if( $BuildNumber )
    {
        $parameters['buildNumber'] = $BuildNumber
    }

    if( $Variable )
    {
        foreach( $key in $Variable.Keys )
        {
            $parameters[('${0}' -f $key)] = $Variable[$key]
        }
    }

    Invoke-BMRestMethod -Session $Session -Name 'releases/builds/create' -Parameter $parameters -Method Post
}