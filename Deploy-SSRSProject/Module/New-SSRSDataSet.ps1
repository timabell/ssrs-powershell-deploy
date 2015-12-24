function New-SSRSDataSet (
	$Proxy,
	[string]$RsdPath,
	[string]$Folder,
	[bool]$Overwrite=$true,
	$DataSourcePaths
) 
{
    
  $script:ErrorActionPreference = 'Stop'
	Write-Verbose "Processing DataSet '$RsdPath'..."

	$Folder = Normalize-SSRSFolder -Folder $Folder

	$Name =  [System.IO.Path]::GetFileNameWithoutExtension($RsdPath)
	$RawDefinition = Get-Content -Encoding Byte -Path $RsdPath
	$properties = $null
	$warnings = $null

	# https://msdn.microsoft.com/en-us/library/reportservice2010.reportingservice2010.createcatalogitem.aspx
	$Results = $Proxy.CreateCatalogItem("DataSet", $Name, $Folder, $Overwrite, $RawDefinition, $properties, [ref]$warnings)

	[xml]$Rsd = Get-Content -Path $RsdPath
	$DataSourcePath = $DataSourcePaths[$Rsd.SharedDataSet.DataSet.Query.DataSourceReference]
	if ($DataSourcePath) {
		$Reference = New-Object -TypeName SSRS.ReportingService2010.ItemReference
		$Reference.Reference = $DataSourcePath
		$Reference.Name = 'DataSetDataSource' #$Rsd.SharedDataSet.DataSet.Name

		$Proxy.SetItemReferences($Folder + '/' + $Name, @($Reference))

	}
	return $Results
}