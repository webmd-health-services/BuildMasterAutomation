#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#Helper functions for PackageManagement DSC Resouces

Import-LocalizedData -BindingVariable LocalizedData -filename PackageManagementDscUtilities.strings.psd1


 Function ExtractArguments
{
    <#
    .SYNOPSIS

    This is a helper function that extract the parameters from a given table. 

    .PARAMETER FunctionBoundParameters
    Specifies the hashtable containing a set of parameters to be extracted

    .PARAMETER ArgumentNames
    Specifies A list of arguments you want to extract
    #>

    Param
    (
        [parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $FunctionBoundParameters,

        #A list of arguments you want to extract
        [parameter(Mandatory = $true)]
        [System.String[]]$ArgumentNames
    )

    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))

    $returnValue=@{}

    foreach ($arg in $ArgumentNames)
    {
        if($FunctionBoundParameters.ContainsKey($arg))
        {
            #Found an argument we are looking for, so we add it to return collection
            $returnValue.Add($arg,$FunctionBoundParameters[$arg])
        }
    }

    return $returnValue
 }

function ThrowError
{
    <#
    .SYNOPSIS

    This is a helper function that throws an error. 

    .PARAMETER ExceptionName
    Specifies the type of errors, e.g. System.ArgumentException

    .PARAMETER ExceptionMessage
    Specifies the exception message

    .PARAMETER ErrorId
    Specifies an identifier of the error

    .PARAMETER ErrorCategory
    Specifies the error category, e.g., InvalidArgument defined in System.Management.Automation. 

    #>

    param
    (        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]        
        $ExceptionName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionMessage,      
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )
    
    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))
        
    $exception   = New-Object -TypeName $ExceptionName -ArgumentList $ExceptionMessage;
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList ($exception, $ErrorId, $ErrorCategory, $null)    
    throw $errorRecord
}

Function ValidateArgument
{
    <#
    .SYNOPSIS

    This is a helper function that validates the arguments. 

    .PARAMETER Argument
    Specifies the argument to be validated.

    .PARAMETER Type
    Specifies the type of argument.
    #>

    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Argument,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Type,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ProviderName
    )

    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))

    switch ($Type)
    {

        "SourceUri"
        {
            # Checks whether given URI represents specific scheme
            # Most common schemes: file, http, https, ftp        
            $scheme =@('http', 'https', 'file', 'ftp')
 
            $newUri = $Argument -as [System.URI]  
            $returnValue = ($newUri -and $newUri.AbsoluteURI -and ($scheme -icontains $newuri.Scheme)) 

            if ($returnValue -eq $false)
            {                
                ThrowError  -ExceptionName "System.ArgumentException" `
                            -ExceptionMessage ($LocalizedData.InValidUri -f $Argument)`
                            -ErrorId "InValidUri" `
                            -ErrorCategory InvalidArgument
            }
            
            #Check whether it's a valid uri. Wait for the response within 2mins.
            <#$result = Invoke-WebRequest $newUri -TimeoutSec 120 -UseBasicParsing -ErrorAction SilentlyContinue

            if ($null -eq (([xml]$result.Content).service ))
            {
                ThrowError  -ExceptionName "System.ArgumentException" `
                            -ExceptionMessage ($LocalizedData.InValidUri -f $Argument)`
                            -ErrorId "InValidUri" `
                            -ErrorCategory InvalidArgument
            }#>
                                         
        }
        "DestinationPath"
        {
            $returnValue = Test-Path -Path $Argument
            if ($returnValue -eq $false)
            {
                ThrowError  -ExceptionName "System.ArgumentException" `
                            -ExceptionMessage ($LocalizedData.PathDoesNotExist -f $Argument)`
                            -ErrorId "PathDoesNotExist" `
                            -ErrorCategory InvalidArgument
            }
        }
        "PackageSource"
        {      
            #Argument can be either the package source Name or source Uri.  
            
            #Check if the source is a uri 
            $uri = $Argument -as [System.URI]  

            if($uri -and $uri.AbsoluteURI) 
            {
                # Check if it's a valid Uri
                ValidateArgument -Argument $Argument -Type "SourceUri" -ProviderName $ProviderName
            }
            else
            {
                #Check if it's a registered package source name                                                             
                $source = PackageManagement\Get-PackageSource -Name $Argument -ProviderName $ProviderName -verbose -ErrorVariable ev
                if ((-not $source) -or $ev) 
                {
                    #We do not need to throw error here as Get-PackageSource does already
                    Write-Verbose -Message ($LocalizedData.SourceNotFound -f $source)                
                }
            }
        }
        default
        {
            ThrowError  -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage ($LocalizedData.UnexpectedArgument -f $Type)`
                        -ErrorId "UnexpectedArgument" `
                        -ErrorCategory InvalidArgument
        }
     }           
}

Function ValidateVersionArgument
{
    <#
    .SYNOPSIS

    This is a helper function that does the version validation. 

    .PARAMETER RequiredVersion
    Provides the required version.

    .PARAMETER MaximumVersion
    Provides the maximum version.

    .PARAMETER MinimumVersion
    Provides the minimum version.
    #>

    [CmdletBinding()]
    param
    (
        [string]$RequiredVersion,
        [string]$MinimumVersion,
        [string]$MaximumVersion

    )
         
    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))

    $isValid = $false
         
    #Case 1: No further check required if a user provides either none or one of these: minimumVersion, maximumVersion, and requiredVersion
    if ($PSBoundParameters.Count -le 1)
    {
        return $true
    }

    #Case 2: #If no RequiredVersion is provided 
    if (-not $PSBoundParameters.ContainsKey('RequiredVersion'))
    {
        #If no RequiredVersion, both MinimumVersion and MaximumVersion are provided. Otherwise fall into the Case #1
        $isValid = $PSBoundParameters['MinimumVersion'] -le $PSBoundParameters['MaximumVersion']
    }
    
    #Case 3: RequiredVersion is provided. 
    #        In this case  MinimumVersion and/or MaximumVersion also are provided. Otherwise fall in to Case #1.
    #        This is an invalid case. When RequiredVersion is provided, others are not allowed. so $isValid is false, which is already set in the init

    if ($isValid -eq $false)
    {        
        ThrowError  -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage ($LocalizedData.VersionError)`
                    -ErrorId "VersionError" `
                    -ErrorCategory InvalidArgument
    }
}

Function Get-InstallationPolicy
{
    <#
    .SYNOPSIS

    This is a helper function that retrives the InstallationPolicy from the given repository. 

    .PARAMETER RepositoryName
    Provides the repository Name.

    #>

    Param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$RepositoryName
    )

    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))

    $repositoryobj = PackageManagement\Get-PackageSource -Name $RepositoryName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    if ($repositoryobj)
    {      
        return $repositoryobj.IsTrusted
    }                  
}

# SIG # Begin signature block
# MIIjhgYJKoZIhvcNAQcCoIIjdzCCI3MCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD+xe8u4YoS6UEO
# jtW70wceL89huvuluOvdcbeefpOXLqCCDYEwggX/MIID56ADAgECAhMzAAABUZ6N
# j0Bxow5BAAAAAAFRMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMTkwNTAyMjEzNzQ2WhcNMjAwNTAyMjEzNzQ2WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCVWsaGaUcdNB7xVcNmdfZiVBhYFGcn8KMqxgNIvOZWNH9JYQLuhHhmJ5RWISy1
# oey3zTuxqLbkHAdmbeU8NFMo49Pv71MgIS9IG/EtqwOH7upan+lIq6NOcw5fO6Os
# +12R0Q28MzGn+3y7F2mKDnopVu0sEufy453gxz16M8bAw4+QXuv7+fR9WzRJ2CpU
# 62wQKYiFQMfew6Vh5fuPoXloN3k6+Qlz7zgcT4YRmxzx7jMVpP/uvK6sZcBxQ3Wg
# B/WkyXHgxaY19IAzLq2QiPiX2YryiR5EsYBq35BP7U15DlZtpSs2wIYTkkDBxhPJ
# IDJgowZu5GyhHdqrst3OjkSRAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUV4Iarkq57esagu6FUBb270Zijc8w
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDU0MTM1MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAWg+A
# rS4Anq7KrogslIQnoMHSXUPr/RqOIhJX+32ObuY3MFvdlRElbSsSJxrRy/OCCZdS
# se+f2AqQ+F/2aYwBDmUQbeMB8n0pYLZnOPifqe78RBH2fVZsvXxyfizbHubWWoUf
# NW/FJlZlLXwJmF3BoL8E2p09K3hagwz/otcKtQ1+Q4+DaOYXWleqJrJUsnHs9UiL
# crVF0leL/Q1V5bshob2OTlZq0qzSdrMDLWdhyrUOxnZ+ojZ7UdTY4VnCuogbZ9Zs
# 9syJbg7ZUS9SVgYkowRsWv5jV4lbqTD+tG4FzhOwcRQwdb6A8zp2Nnd+s7VdCuYF
# sGgI41ucD8oxVfcAMjF9YX5N2s4mltkqnUe3/htVrnxKKDAwSYliaux2L7gKw+bD
# 1kEZ/5ozLRnJ3jjDkomTrPctokY/KaZ1qub0NUnmOKH+3xUK/plWJK8BOQYuU7gK
# YH7Yy9WSKNlP7pKj6i417+3Na/frInjnBkKRCJ/eYTvBH+s5guezpfQWtU4bNo/j
# 8Qw2vpTQ9w7flhH78Rmwd319+YTmhv7TcxDbWlyteaj4RK2wk3pY1oSz2JPE5PNu
# Nmd9Gmf6oePZgy7Ii9JLLq8SnULV7b+IP0UXRY9q+GdRjM2AEX6msZvvPCIoG0aY
# HQu9wZsKEK2jqvWi8/xdeeeSI9FN6K1w4oVQM4Mwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIVWzCCFVcCAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAVGejY9AcaMOQQAAAAABUTAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgCZ2K5xbK
# 27tyibqtMV5AHpyNN7lNy3nCNEZ+gshCPtAwQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQAsgLg84mzgUnHg/KPV8sG/XXc5x8BHF+i2Jx4qPtQQ
# iq5s1TYeEH95mleSYQDoy23wtFJ3iel7U9LJf379b0KICs+ffHCsSw9p9+QXyBw9
# ECrKtzhHQC29ubmF+B40cxrMBoZQGHnHzDzFQmJYCJ2B6gSHwmZCwM/pgk/8xgi2
# zPo7Ag7pL8PEvgas9FJoBS0MRiKCMGH3+wjb/DDudI4XgiNPjuVx8s3yhEEa0HRL
# 4RdFeODlPL0oWKKiTzcJJG0p/42aIJWiZEJfRL7txSEjKdEbMk4PYgHdyRSqxrpG
# c6CBfXqGNro7mX/6UwfQlnKVJF0pmL70GGpL1P6FKpKWoYIS5TCCEuEGCisGAQQB
# gjcDAwExghLRMIISzQYJKoZIhvcNAQcCoIISvjCCEroCAQMxDzANBglghkgBZQME
# AgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEILObKLsu5NP7gXmtPxYMH9AIP436qdHPD8XXHxZA
# HSjvAgZcyeI2lr8YEzIwMTkwNjE3MjAyNjU3Ljk4NFowBIACAfSggdCkgc0wgcox
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1p
# Y3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1Mg
# RVNOOkQyQ0QtRTMxMC00QUYxMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNloIIOPDCCBPEwggPZoAMCAQICEzMAAAD50wuyGQEawS0AAAAAAPkw
# DQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcN
# MTgxMDI0MjExNDI5WhcNMjAwMTEwMjExNDI5WjCByjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
# T3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RDJDRC1FMzEwLTRB
# RjExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCt59F4TCmZKO+nf9KZzXldT5atdJrY
# iuhdzE5RC7muoZivL76FktWLcjQ1Xm1ui1SP1SoUJWUSh8lMrchRiWAJGRu5QYuq
# BevvfEW8iK/FNdzu1vnsI5cxbAsoPBqwSj3uHMB6Rhyovtl5PgoP5VgYqk96YjN6
# YalSDzdzSd1xxWxpHGlA65AFLGQzFenPOe2o6j76a4oEnKzz4Eb/x2HNs6iHQzVP
# Lk/aC0o1AQa3sBffwJpDfhYtNbwgpxelGUMB10SbplA6nv0QvE0NghJ5XxqnRsy2
# tmIDzA/Cn93w+KmnrEZAgq+ohYCGr2K8GGMKo+S9NK+ArH4C5Ty7nEihAgMBAAGj
# ggEbMIIBFzAdBgNVHQ4EFgQUjqrRSwYsKtZankFP0Ps+k/omwQMwHwYDVR0jBBgw
# FoAU1WM6XIoxkPNDe3xGG8UzaFqFbVUwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDov
# L2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljVGltU3RhUENB
# XzIwMTAtMDctMDEuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNUaW1TdGFQQ0FfMjAx
# MC0wNy0wMS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDCDAN
# BgkqhkiG9w0BAQsFAAOCAQEAZaab7pU7m87N51+4T01FEClXKBTmLwCiheul3+pz
# ESwe53SUs3eHN9dFrPP+Ob7Djb+hycKXzl1lTpjt9nRKUnAV+NyRfZheGDr4unjy
# lEQqYN6uZNCSzzLChwOM4jLx4fbT4K8ywUKIfTfPWj8W/iY6Ne3mtamqlZJj+Dek
# uAgUdUSAV0GbhDu+qdBwz9afJOhjTBtKj6fvxmm+4jalZK6UsSFx2zF1aQ23t/ED
# 8dAruTO/sJEJ0en25AuNzH7Jh4uulNWboCyC4D56caGyRggk82IpxiN31+ZVLy4a
# zZu//8QkWfHqFhfZa0qd2VaFuZU43PHQ+IUh8KCOD3XbSTCCBnEwggRZoAMCAQIC
# CmEJgSoAAAAAAAIwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRp
# ZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTEwMDcwMTIxMzY1NVoXDTI1MDcwMTIx
# NDY1NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQCpHQ28dxGKOiDs/BOX9fp/aZRrdFQQ1aUKAIKF
# ++18aEssX8XD5WHCdrc+Zitb8BVTJwQxH0EbGpUdzgkTjnxhMFmxMEQP8WCIhFRD
# DNdNuDgIs0Ldk6zWczBXJoKjRQ3Q6vVHgc2/JGAyWGBG8lhHhjKEHnRhZ5FfgVSx
# z5NMksHEpl3RYRNuKMYa+YaAu99h/EbBJx0kZxJyGiGKr0tkiVBisV39dx898Fd1
# rL2KQk1AUdEPnAY+Z3/1ZsADlkR+79BL/W7lmsqxqPJ6Kgox8NpOBpG2iAg16Hgc
# sOmZzTznL0S6p/TcZL2kAcEgCZN4zfy8wMlEXV4WnAEFTyJNAgMBAAGjggHmMIIB
# 4jAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQU1WM6XIoxkPNDe3xGG8UzaFqF
# bVUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1Ud
# EwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYD
# VR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwv
# cHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEB
# BE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9j
# ZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwgaAGA1UdIAEB/wSBlTCB
# kjCBjwYJKwYBBAGCNy4DMIGBMD0GCCsGAQUFBwIBFjFodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vUEtJL2RvY3MvQ1BTL2RlZmF1bHQuaHRtMEAGCCsGAQUFBwICMDQe
# MiAdAEwAZQBnAGEAbABfAFAAbwBsAGkAYwB5AF8AUwB0AGEAdABlAG0AZQBuAHQA
# LiAdMA0GCSqGSIb3DQEBCwUAA4ICAQAH5ohRDeLG4Jg/gXEDPZ2joSFvs+umzPUx
# vs8F4qn++ldtGTCzwsVmyWrf9efweL3HqJ4l4/m87WtUVwgrUYJEEvu5U4zM9GAS
# inbMQEBBm9xcF/9c+V4XNZgkVkt070IQyK+/f8Z/8jd9Wj8c8pl5SpFSAK84Dxf1
# L3mBZdmptWvkx872ynoAb0swRCQiPM/tA6WWj1kpvLb9BOFwnzJKJ/1Vry/+tuWO
# M7tiX5rbV0Dp8c6ZZpCM/2pif93FSguRJuI57BlKcWOdeyFtw5yjojz6f32WapB4
# pm3S4Zz5Hfw42JT0xqUKloakvZ4argRCg7i1gJsiOCC1JeVk7Pf0v35jWSUPei45
# V3aicaoGig+JFrphpxHLmtgOR5qAxdDNp9DvfYPw4TtxCd9ddJgiCGHasFAeb73x
# 4QDf5zEHpJM692VHeOj4qEir995yfmFrb3epgcunCaw5u+zGy9iCtHLNHfS4hQEe
# gPsbiSpUObJb2sgNVZl6h3M7COaYLeqN4DMuEin1wC9UJyH3yKxO2ii4sanblrKn
# QqLJzxlBTeCG+SqaoxFmMNO7dDJL32N79ZmKLxvHIa9Zta7cRDyXUHHXodLFVeNp
# 3lfB0d4wwP3M5k37Db9dT+mdHhk4L7zPWAUu7w2gUDXa7wknHNWzfjUeCLraNtvT
# X4/edIhJEqGCAs4wggI3AgEBMIH4oYHQpIHNMIHKMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBP
# cGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpEMkNELUUzMTAtNEFG
# MTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcG
# BSsOAwIaAxUAAcpZPW4AjkLiMFhLNU9zK8DF0j2ggYMwgYCkfjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOCyVm4wIhgPMjAx
# OTA2MTgwMjExNThaGA8yMDE5MDYxOTAyMTE1OFowdzA9BgorBgEEAYRZCgQBMS8w
# LTAKAgUA4LJWbgIBADAKAgEAAgIM5QIB/zAHAgEAAgIRpjAKAgUA4LOn7gIBADA2
# BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIB
# AAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAJD3NNcIYbWsjbJaLyJvjBsBiXpkmqAc
# QpSj5Q4tz8dMaBMlHzS6CUg7+fLN5MLVkzjs6V3bq4AOj4fRSKus/vYcHQR1lDJt
# 0m7foGo2Ah0+fBDLj3LDequoxzvUAXgnJvTQt3IPoTHpl19bMOnh7xsYWdwCwUqo
# 1v/58T4hj/98MYIDDTCCAwkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
# IDIwMTACEzMAAAD50wuyGQEawS0AAAAAAPkwDQYJYIZIAWUDBAIBBQCgggFKMBoG
# CSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgztxOpKF3
# +S7BoeppMLjTUzHKeB+BfLfdAWMvIZrulAUwgfoGCyqGSIb3DQEJEAIvMYHqMIHn
# MIHkMIG9BCDGo1l2ns8rTUBUtkpPBW84mPUiyjetMQ7CK9tk7lz93zCBmDCBgKR+
# MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
# HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAA+dMLshkBGsEtAAAA
# AAD5MCIEICz4dHdIGMQQKRw90fuvDwIQXk9/m9s0adQo8MtkfmOcMA0GCSqGSIb3
# DQEBCwUABIIBAIYupzTZIx9+IYP/j7e74vdby5dYph4cfmoHXhebRLYgERFIi276
# 2/CA5MZvky3ncxAZwjjzBixbPS0cT2raNs3fMBmLiWHPIl7tR0bznl8FE4/AvChc
# zLbRdzWTYDUNPtc3WjL5nQ1BBAxj53SM4aFrxQEmP4cu6+euQVMAxH52YWpfXhzX
# FIBY1oeBMYEppSPLGBImqR5ouwYCWdTNIf0p+2HtBKM6U0TNDY1l1xi7gAKa0V6H
# InV5L+zxf56l7PqXsgNor8rHK5gj0XCJcn5swA9WDKcIc/GVqXTaqv+CAsh7hgnc
# +s+qI1l9kHKXnv+yA9XmdfYJbgSYuDygyVs=
# SIG # End signature block
