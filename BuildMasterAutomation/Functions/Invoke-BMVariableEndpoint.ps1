
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
        [ValidateSet('application', 'application-group', 'environment', 'global', 'server', 'role')]
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
            'application' = 'application';
            'application-group' = 'application group';
            'environment' = 'environment';
            'server' = 'server';
            'role' = 'server role'
        }
        $entityDesc = $entityTypeDescriptions[$EntityTypeName]
        $entityDescCapitalized = [char]::ToUpperInvariant($entityDesc[0]) + $entityDesc.Substring(1)

        $entityToParamNameMap = @{
            'application' = 'Application';
            'application-group' = 'ApplicationGroup';
            'environment' = 'Environment';
            'server' = 'Server';
            'role' = 'ServerRole';
        }

        # What parameter has the variable's entity?
        $paramName = $entityToParamNameMap[$EntityTypeName]

        # Get the entity.
        $entity = $BoundParameter[$paramName]

        $getEntityArg = @{
            $paramName = $entity;
        }
        # Check if the entity exists in BuildMaster.
        $bmEntity = & "Get-BM$($paramName)" -Session $Session @getEntityArg -ErrorAction Ignore
        if (-not $bmEntity)
        {
            $entityName = $entity | Get-BMObjectName
            $msg = "$($entityDescCapitalized) ""$($entityName)"" does not exist."
            if ($deleting)
            {
                $msg = "Unable to delete variable ""$($variableName)"" because the $($entityDesc) " +
                       """$($entityName)"" does not exist."
            }
            elseif ($updating)
            {
                $msg = "Unable to set variable ""$($variableName)"" because the $($entityDesc) ""$($entityName)"" " +
                       'does not exist.'
            }
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        # Get the entity's name.
        $entityName = $bmEntity | Get-BMOBjectName -Strict -ObjectTypeName $paramName

        # Create the entity-specific endpoint path.
        $entityPathSegment = "$($entityTypeName)/$([Uri]::EscapeDataString($entityName))$($variablePathSegment)"
    }

    $endpointPath = "variables/$($entityPathSegment)"

    $variables = @{}
    if (-not $updating)
    {
        $variables = Invoke-BMRestMethod -Session $session -Name $endpointPath
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
        Invoke-BMRestMethod -Session $session -Name $endpointPath -Method Delete
        return
    }

    if ($updating)
    {
        Invoke-BMRestMethod -Session $session -Name $endpointPath -Body $Value -Method Post
        return
    }

    if ($variables -is [String])
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