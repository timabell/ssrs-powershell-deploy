
function New-SSRSDataSource (
	$Proxy,
	[string]$RdsPath,
	[string]$Folder,
	[bool]$Overwrite
)
{
	$script:ErrorActionPreference = 'Stop'

	Write-Verbose "Processing DataSource '$RdsPath'..."

	$Folder = Normalize-SSRSFolder -Folder $Folder

	[xml]$Rds = Get-Content -Path $RdsPath
	$ConnProps = $Rds.RptDataSource.ConnectionProperties

	$Definition = New-Object -TypeName SSRS.ReportingService2010.DataSourceDefinition
	$Definition.ConnectString = $ConnProps.ConnectString
	$Definition.Extension = $ConnProps.Extension

	$connectionString = New-Object System.Data.Common.DbConnectionStringBuilder
	$connectionString.set_ConnectionString($ConnProps.ConnectString)

	#Does the IntegratedSecurity property exist
	$integratedproperty = $ConnProps | Get-Member -MemberType Property | where {$_.name -like 'IntegratedSecurity'}

	if($integratedproperty -ne $null)
	{
		if ([Convert]::ToBoolean($ConnProps.IntegratedSecurity)) {
			$Definition.CredentialRetrieval = 'Integrated'
		}
	}
	else{
		write-verbose "IntegratedSecurity Missing"

		$Definition.CredentialRetrieval = 'Store'
		$Definition.UserName = $connectionString['User ID']
		$Definition.Password = $connectionString['Password']
	}

	$DataSource = New-Object -TypeName PSObject -Property @{
		Name = $Rds.RptDataSource.Name
		Path = $Folder + '/' + $Rds.RptDataSource.Name
	}

	$exists = $Proxy.GetItemType($DataSource.Path) -ne 'Unknown'
	$write = $false
	if ($exists) {
		if ($Overwrite) {
			Write-Verbose " - overwriting"
			$write = $true
		} else {
			Write-Verbose " - skipped, already exists"
		}
	} else {
		Write-Verbose " - creating new"
		$write = $true
	}

	if ($write) {
		# assign result to avoid polluting return value. http://stackoverflow.com/a/23225503/10245
		# Oh what an ugly language powerhell is. :-/
		$foo = $Proxy.CreateDataSource($DataSource.Name, $Folder, $Overwrite, $Definition, $null)
	}

	return $DataSource
}
