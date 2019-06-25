#
# Module manifest for module 'BuildMasterAutomation'
#
# Generated by: Lifecycle Services
#
# Generated on: 1/17/2017
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'BuildMasterAutomation.psm1'

    # Version number of this module.
    ModuleVersion = '0.6.0'

    # ID used to uniquely identify this module
    GUID = 'cc5a1865-e5f8-45f2-b0d3-317a1611a965'

    # Author of this module
    Author = 'WebMD Health Services'

    # Company or vendor of this module
    CompanyName = 'WebMD Health Services'

    # Copyright statement for this module
    Copyright = '(c) 2017 - 2018 WebMD Health Services. All rights reserved.'

    # Description of the functionality provided by this module
    Description = @'
The BuildMasterAutomation module is a PowerShell module for working with BuildMaster web APIs. BuildMaster is an application deployment automation tool by Inedo software. This module wraps its web APIs in a PowerShell interface. It allows you to read and create applications, releases, packages, etc. If this module doesn't have a function for a specific API endpoint, it has generic `Invoke-BMRestMethod` and `Invoke-BMNativeApimethod` functions that take the pain out of creating the proper web requests.
'@

    # Minimum version of the Windows PowerShell engine required by this module
    # PowerShellVersion = ''

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module
    FunctionsToExport = @(
                            'Add-BMObjectParameter',
                            'Disable-BMApplication',
                            'Get-BMApplication',
                            'Get-BMApplicationGroup',
                            'Get-BMDeployment',
                            'Get-BMRelease',
                            'Get-BMPackage',
                            'Get-BMPipeline',
                            'Invoke-BMNativeApiMethod',
                            'Invoke-BMRestMethod',
                            'New-BMApplication',
                            'New-BMPipeline',
                            'New-BMRelease',
                            'New-BMPackage',
                            'New-BMSession',
                            'Publish-BMReleasePackage',
                            'Set-BMRelease',
                            'Stop-BMRelease'
                         )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @( 'buildmaster', 'inedo', 'devops', 'automation', 'pipeline', 'deploy' )

            # A URL to the license for this module.
            LicenseUri = 'https://www.apache.org/licenses/LICENSE-2.0'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/webmd-health-services/BuildMasterAutomation'

            # A URL to an icon representing this module.
            # IconUri = ''

            # Any prerelease to use when publishing to a repository.
            Prerelease = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
* Created `Get-BMDeployment` function to retrieve deployment information for release packages.
'@
        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
