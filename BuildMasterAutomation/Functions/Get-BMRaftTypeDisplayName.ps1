
function Get-BMRaftTypeDisplayName
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull() ]
        [BMRaftItemTypeCode] $TypeCode
    )

    process
    {
        if ($null -eq $TypeCode)
        {
            return 'Raft Item'
        }

        switch ($TypeCode)
        {
            'DeploymentPlan' { return 'Deployment Plan' }
            default { $TypeCode.ToString() }
        }
    }
}