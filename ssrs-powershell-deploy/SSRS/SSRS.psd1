@{
	RootModule = "SSRS"
	ModuleVersion = '1.3.0'
	GUID = '58a90a5a-fba6-464c-8906-65d78d08d398'
	Author = 'Tim Abell and others'
	Description = 'https://github.com/timabell/ssrs-powershell-deploy - PowerShell module to deploy SQL Server Reporting Services project(s) (`.rptproj`) to a Reporting Server'
	HelpInfoURI = 'https://github.com/timabell/ssrs-powershell-deploy'
	FunctionsToExport = @("Publish-SSRSProject", "Publish-SSRSSolution")
}

