
function Get-BMDeployment
{
    <#
    .SYNOPSIS
    Gets a deployment from BuildMaster.

    .DESCRIPTION
    The `Get-BMDeployment` function gets deployments in BuildMaster. It uses the [Release and Package Deployment API](http://inedo.com/support/documentation/buildmaster/reference/api/release-and-package).

    To get a specific deployment, pass a deploymentID.

    To get all the deployments for a specific package, pass a package object to the `Package` parameter (a package object must have a `packageId` or `packageNumber` property).

    To get all the deployments for a specific release, pass a release object to the `Release` parameter (a release object must have a `releaseId` or `releaseName` property).

    To get all the deployments for a specific application, pass an application object to the `Application` parameter (an application object must have an `applicationId` or `applicationName` property).

    .EXAMPLE
    Get-BMDeployment -Session $session

    Demonstrates how to get all deployments from the instance of BuildMaster.

    .EXAMPLE
    Get-BMDeployment -Session $session -Deployment $deployment

    Demonstrates how to get a specific deployment by passing a deployment object to the `Deployment` parameter. The `Get-BMDeployment` function looks for an `id` property on the object.

    .EXAMPLE
    Get-BMDeployment -Session $session -Package $package

    Demonstrates how to get all deployments for a package by passing a package object to the `Package` parameter. The `Get-BMDeployment` function looks for an `id` or `number` property on the object.

    .EXAMPLE
    Get-BMDeployment -Session $session -Release $release

    Demonstrates how to get all deployments for a release by passing a release object to the `Release` parameter. The `Get-BMDeployment` function looks for an `id` or `name` property on the object.

    .EXAMPLE
    Get-BMDeployment -Session $session -Application $app

    Demonstrates how to get all deployments for an application by passing an application object to the `Application` parameter. The `Get-BMDeployment` function looks for an `id` or `name` property on the object.

    .EXAMPLE
    Get-BMDeployment -Session $session -Application 34

    Demonstrates how to get all deployments for an application by passing its ID to the `Application` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='AllDeployments')]
    param(
        [Parameter(Mandatory)]
        [object]
        # A session object that contains the settings to use to connect to BuildMaster. Use `New-BMSession` to create session objects.
        $Session,

        [Parameter(Mandatory,ParameterSetName='ByDeployment')]
        [object]
        # The deployment to get. You can pass:
        #
        # * A deployment ID (as an integer)
        $Deployment,

        [Parameter(Mandatory,ParameterSetName='ByPackage')]
        [object]
        # The package whose deployments to get. You can pass:
        #
        # * A package ID as an integer
        # * A package name/number as a string.
        $Package,

        [Parameter(Mandatory,ParameterSetName='ByRelease')]
        [object]
        # The release whose deployments to get. You can pass:
        #
        # * The release ID as an integer.
        # * The release name as a string.
        $Release,

        [Parameter(Mandatory,ParameterSetName='ByApplication')]
        [object]
        # The application whose deployments to get. You can pass:
        #
        # * The application ID as an integer.
        # * The application name as a string.
        $Application
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $parameter = @{ }
        if( $PSCmdlet.ParameterSetName -eq 'ByDeployment' )
        {
            $parameter | Add-BMObjectParameter -Name 'deployment' -Value $Deployment
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'ByPackage' )
        {
            if( $Package -is [string] )
            {
                $parameter['packageNumber'] = $Package
            }
            else
            {
                $parameter | Add-BMObjectParameter -Name 'package' -Value $Package
            }
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'ByRelease' )
        {
            $parameter | Add-BMObjectParameter -Name 'release' -Value $Release
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'ByApplication' )
        {
            $parameter | Add-BMObjectParameter -Name 'application' -Value $Application
        }

        Invoke-BMRestMethod -Session $Session -Name 'releases/packages/deployments' -Parameter $parameter -Method Post
    }
}
