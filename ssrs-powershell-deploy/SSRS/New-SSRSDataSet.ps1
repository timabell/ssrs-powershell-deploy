function New-SSRSDataSet (
	$Proxy,
	[string]$RsdPath,
	[string]$Folder,
	[bool]$Overwrite=$false,
	$DataSourcePaths
)
{

	$script:ErrorActionPreference = 'Stop'
	Write-Verbose "Processing DataSet '$RsdPath'..."

	$Folder = Normalize-SSRSFolder -Folder $Folder

	$Name =  [System.IO.Path]::GetFileNameWithoutExtension($RsdPath)
	$RawDefinition = Get-Content -Encoding Byte -Path $RsdPath
	[xml]$Rsd = Get-Content -Path $RsdPath
	$properties = $null
	$warnings = $null

	#Nevermind it always uses filename
	 # if([string]::IsNullOrEmpty($Rsd.SharedDataSet.DataSet.Name ))
	 # {
		# $Rsd.SharedDataSet.DataSet.Name=$Name
	 # }

	$FakeResult = New-Object -TypeName PSObject -Property @{
		Name = $Rsd.SharedDataSet.DataSet.Name
		Path = $Folder + '/' + $Name
	}

	$exists = $Proxy.GetItemType($FakeResult.Path) -ne 'Unknown'
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

		# https://msdn.microsoft.com/en-us/library/reportservice2010.reportingservice2010.createcatalogitem.aspx
		$Results = $Proxy.CreateCatalogItem("DataSet", $Name, $Folder, $Overwrite, $RawDefinition, $properties, [ref]$warnings)

		$DataSourcePath = $DataSourcePaths[$Rsd.SharedDataSet.DataSet.Query.DataSourceReference]
		if ($DataSourcePath) {
			$Reference = New-Object -TypeName SSRS.ReportingService2010.ItemReference
			$Reference.Reference = $DataSourcePath
			$Reference.Name = 'DataSetDataSource' #$Rsd.SharedDataSet.DataSet.Name

			$Proxy.SetItemReferences($Folder + '/' + $Name, @($Reference))

		}
	}
	else{
		$Results=$FakeResult;
	}
	return $Results
}
