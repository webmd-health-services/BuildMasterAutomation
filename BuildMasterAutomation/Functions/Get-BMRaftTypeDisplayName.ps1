
function Get-BMRaftTypeDisplayName
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [BMRaftItemTypeCode] $TypeCode
    )

    process
    {
        switch ($TypeCode)
        {
            'DeploymentPlan' { return 'Deployment Plan' }
            default { $TypeCode.ToString() }
        }
    }
}