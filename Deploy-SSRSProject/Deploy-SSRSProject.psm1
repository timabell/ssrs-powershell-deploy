# Handle location because SQLPS is ... not helpful in this regard.
$loc = Get-Location
Import-Module SQLPS -DisableNameChecking
Set-Location $loc

@("$PSScriptRoot\*.ps1") | Resolve-Path |
  % { . $_.ProviderPath }

Export-ModuleMember Deploy-SSRSProject
Export-ModuleMember Get-SSRSProjectConfiguration
Export-ModuleMember New-SSRSWebServiceProxy
