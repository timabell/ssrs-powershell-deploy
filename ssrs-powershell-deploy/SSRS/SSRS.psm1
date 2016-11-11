
#Dot source all ps1 files
#These are the small function used by others
. $PSScriptRoot\Get-SSRSCredential.ps1
. $PSScriptRoot\Normalize-SSRSFolder.ps1
. $PSScriptRoot\New-XmlNamespaceManager.ps1

. $PSScriptRoot\New-SSRSFolder.ps1
. $PSScriptRoot\New-SSRSDataSource.ps1
. $PSScriptRoot\New-SSRSDataSet.ps1
. $PSScriptRoot\New-SSRSReport.ps1


#Larger methods that might use some of the ones above
. $PSScriptRoot\New-SSRSWebServiceProxy.ps1
. $PSScriptRoot\Get-SSRSProjectConfiguration.ps1
. $PSScriptRoot\Publish-SSRSProject.ps1
. $PSScriptRoot\Publish-SSRSSolution.ps1

Export-ModuleMember Get-SSRSCredential, Normalize-SSRSFolder, New-XmlNamespaceManager, New-SSRSFolder, New-SSRSDataSource, New-SSRSDataSet, New-SSRSReport, New-SSRSWebServiceProxy, Get-SSRSProjectConfiguration, Publish-SSRSProject, Publish-SSRSSolution
