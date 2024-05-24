
function Invoke-BMVariableEndpoint
{
    [CmdletBinding(DefaultParameterSetName='Get')]
    param(
        [Parameter(Mandatory)]
        [Object] $Session,

        [Parameter(Mandatory, ParameterSetName='Delete')]
        [Parameter(ParameterSetName='Get')]
        [Parameter(Mandatory, ParameterSetName='Set')]
        [Object] $Variable,

        [Parameter(Mandatory, ParameterSetName='Set')]
        [String] $Value,

        [Parameter(Mandatory)]
        [ValidateSet('application', 'application-group', 'environment', 'global', 'server', 'role', 'releases', 'builds')]
        [String] $EntityTypeName,

        [Parameter(Mandatory)]
        [hashtable] $BoundParameter,

        [Parameter(Mandatory, ParameterSetName='Delete')]
        [switch] $ForDelete
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $variableName = ''
    $getting = $PSCmdlet.ParameterSetName -eq 'Get'
    $deleting = $ForDelete.IsPresent
    $updating = $PSCmdlet.ParameterSetName -eq 'Set'
    if ($Variable)
    {
        $variableName = $Variable | Get-BMObjectName -Strict
        if (-not $variableName -and ($deleting -or $updating))
        {
            return
        }
    }

    $searching = $getting -and $variableName -and [wildcardpattern]::ContainsWildcardCharacters($variableName)

    $variablePathSegment = ''
    if ($variableName -and -not $searching)
    {
        $variablePathSegment = "/$([Uri]::EscapeDataString($variableName))"
    }

    $entityPathSegment = "global$($variablePathSegment)"

    $entityName = ''
    $bmEntity = $null
    $entityDesc = ''

    if ($EntityTypeName -ne 'global')
    {
        $entityTypeDescriptions = @{
            'application'       = 'application';
            'application-group' = 'application group';
            'environment'       = 'environment';
            'server'            = 'server';
            'role'              = 'server role';
            'releases'          = 'release';
            'builds'            = 'build';
        }
        $entityDesc = $entityTypeDescriptions[$EntityTypeName]
        $entityDescCapitalized = [char]::ToUpperInvariant($entityDesc[0]) + $entityDesc.Substring(1)

        $entityToParamNameMap = @{
            'application'       = 'Application';
            'application-group' = 'ApplicationGroup';
            'environment'       = 'Environment';
            'server'            = 'Server';
            'role'              = 'ServerRole';
            'releases'          = 'Release';
            'builds'            = 'Build';
        }

        # What parameter has the variable's entity?
        $paramName = $entityToParamNameMap[$EntityTypeName]

        # Get the entity.
        $entity = $BoundParameter[$paramName]

        $getEntityArg = @{
            $paramName = $entity;
        }

        if ($EntityTypeName -in @('releases', 'builds'))
        {
            if ($entity.GetType().Name -ne 'PSCustomObject')
            {
                $msg = "The ${paramName} parameter must be a ${paramName} object from the Get-BM${paramName} " +
                       "function, but it was a $($entity.GetType().Name) ""${entity}""."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }

            # It's required to pass in an object for variables on Releases and Builds, therefore we know those already
            # exists and can use the objects directly.
            $entityPathSegment = "${EntityTypeName}/$([Uri]::EscapeDataString($entity.applicationName))/$([Uri]::EscapeDataString($entity.releaseNumber))"

            if ($EntityTypeName -eq 'builds')
            {
                $entityPathSegment = "${entityPathSegment}/$([Uri]::EscapeDataString($entity.buildNumber))"
            }

            $entityPathSegment = "${entityPathSegment}${variablePathSegment}"
        }
        else
        {
            # Check if the entity exists in BuildMaster.
            $bmEntity = & "Get-BM$($paramName)" -Session $Session @getEntityArg -ErrorAction Ignore
            if (-not $bmEntity)
            {
                $entityName = $entity | Get-BMObjectName
                $msg = "$($entityDescCapitalized) ""$($entityName)"" does not exist."
                if ($deleting)
                {
                    $msg = "Unable to delete variable ""$($variableName)"" because $($entityDesc) " +
                        """$($entityName)"" does not exist."
                }
                elseif ($updating)
                {
                    $msg = "Unable to set variable ""$($variableName)"" because $($entityDesc) ""$($entityName)"" " +
                        'does not exist.'
                }
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }

            $entityName = $bmEntity | Get-BMOBjectName -Strict -ObjectTypeName $paramName

            # Create the entity-specific endpoint path.
            $entityPathSegment = "$($EntityTypeName)/$([Uri]::EscapeDataString($entityName))$($variablePathSegment)"
        }
    }

    $endpointPath = "variables/$($entityPathSegment)"

    $variables = @{}

    $nativeApiEntityIdParam = @{}
    [Object[]] $nativeVariables = @()
    $useNativeApi = $EntityTypeName -in @('application', 'application-group')
    if ($EntityTypeName -eq 'application')
    {
        $nativeApiEntityIdParam['Application_Id'] = $bmEntity.Application_Id
    }
    elseif ($EntityTypeName -eq 'application-group')
    {
        $nativeApiEntityIdParam['ApplicationGroup_Id'] = $bmEntity.ApplicationGroup_Id
    }

    if (-not $updating)
    {
        if ($useNativeApi)
        {
            $nativeVariables = Invoke-BMNativeApiMethod -Session $Session `
                                                        -Name 'Variables_GetVariablesForScope' `
                                                        -Method Post `
                                                        -Parameter $nativeApiEntityIdParam

            foreach ($nativeVar in $nativeVariables)
            {
                $bytes = [Convert]::FromBase64String($nativeVar.Variable_Value)
                $variables[$nativeVar.Variable_Name] = [Text.Encoding]::UTF8.GetString($bytes)
            }
            $variables = [pscustomobject]$variables
        }
        else
        {
            $variables = Invoke-BMRestMethod -Session $session -Name $endpointPath
        }
    }

    if ($Variable -and -not $searching -and -not $variables -and -not $updating)
    {
        $msg = "Variable ""$($variableName)"" does not exist."
        if ($bmEntity)
        {
            $msg = "$($entityDescCapitalized) ""$($entityName)"" variable ""$($variableName)"" does not exist."
        }

        if ($ForDelete)
        {
            $msg = "Unable to delete variable ""$($variableName)"" because it does not exist."
            if ($bmEntity)
            {
                $msg = "Unable to delete $($entityDesc) ""$($entityName)"" variable ""$($variableName)"" because the " +
                       "variable does not exist."
            }
        }

        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    if ($deleting)
    {
        if ($useNativeApi)
        {
            $nativeVar = $nativeVariables | Where-Object 'Variable_Name' -EQ $variableName
            Invoke-BMNativeApiMethod -Session $session `
                                     -Name 'Variables_DeleteVariable' `
                                     -Method Post `
                                     -Parameter @{ Variable_Id = $nativeVar.Variable_Id }
        }
        Invoke-BMRestMethod -Session $session -Name $endpointPath -Method Delete
        return
    }

    if ($updating)
    {
        Invoke-BMRestMethod -Session $session -Name $endpointPath -Body $Value -Method Post
        return
    }

    if ($variables.GetType().Name -ne 'PSCustomObject')
    {
        return [pscustomobject]@{
            Name = $variableName;
            Value = $variables;
        }
    }

    $variables |
        Get-Member -MemberType NoteProperty |
        ForEach-Object {
            return [pscustomobject]@{
                'Name' = $_.Name;
                'Value' = $variables.($_.Name);
            }
        } |
        Where-Object {
            if ($variableName)
            {
                return $_.Name -like $variableName
            }
            return $true
        } |
        Write-Output
}
