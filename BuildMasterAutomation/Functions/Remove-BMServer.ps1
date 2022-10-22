
function Remove-BMServer
{
    <#
    .SYNOPSIS
    Removes a server from BuildMaster.

    .DESCRIPTION
    The `Remove-BMServer` function removes a server from BuildMaster. Pass the name of the server to remove to the
    `Name` parameter. If the server doesn't exist, an error is written. To ignore if the server exists or not, set the
    `ErrorAction` parameter to `Ignore`.

    Pass the session to the BuildMaster instance where you want to delete the server to the `Session` parameter. Use
    `New-BMSession` to create a session object.

    This function uses BuildMaster's infrastructure management API.

    .EXAMPLE
    Remove-BMServer -Session $session -Name 'example.com'

    Demonstrates how to delete a server.

    .EXAMPLE
    Get-BMServer -Session $session -Name 'example.com' | Remove-BMServer -Session $session

    Demonstrates that you can pipe the objects returned by `Get-BMServer` into `Remove-BMServer` to remove those
    servers.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "")]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The instance of BuildMaster to connect to.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The server to delete. Pass a server id, name, or a server object.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $Server
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $foundServer = $Server | Get-BMServer -Session $session -ErrorAction Ignore
        if (-not $foundServer)
        {
            $msg = "Could not delete server ""$($Server | Get-BMObjectName)"" because it does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $encodedName = [Uri]::EscapeDataString(($Server | Get-BMObjectName))
        Invoke-BMRestMethod -Session $Session `
                            -Name ('infrastructure/servers/delete/{0}' -f $encodedName) `
                            -Method Delete
    }
}