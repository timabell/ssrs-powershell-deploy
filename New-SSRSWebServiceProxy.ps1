#requires -version 2.0
[CmdletBinding()]
param (
    [parameter(Mandatory=$true)]
    [ValidatePattern('^https?://')]
    [string]
    $Uri,
    
    [System.Management.Automation.PSCredential]
    $Credential
) 

$script:ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $Uri.EndsWith('.asmx')) {
    if (-not $Uri.EndsWith('/')) {
        $Uri += '/'
    }
    $Uri += 'ReportService2005.asmx'
}

$Assembly = [AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object {
        $_.GetType('SSRS.ReportingService2005.ReportingService2005')
    }
if (($Assembly | Measure-Object).Count -gt 1) {
    throw 'AppDomain contains multiple definitions of the same type. Restart PowerShell host.'
}

if (-not $Assembly) {

    if ($Credential) {
        $CredParams = @{ Credential = $Credential }
    } else {
        $CredParams = @{ UseDefaultCredential = $true }
    }            
    $Proxy = New-WebServiceProxy -Uri $Uri -Namespace SSRS.ReportingService2005 @CredParams

} else {

    $Proxy = New-Object -TypeName SSRS.ReportingService2005.ReportingService2005
    if ($Credential) {
        $Proxy.Credentials = $Credential.GetNetworkCredential()
    } else {
        $Proxy.UseDefaultCredentials = $true
    }

}

$Proxy.Url = $Uri
return $Proxy
