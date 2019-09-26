function Get-SSRSProjectConfiguration{
	#requires -version 2.0
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$true)]
		[ValidatePattern('\.rptproj$')]
		[ValidateScript({ Test-Path -PathType Leaf -Path $_ })]
		[string]
		$Path,

		[parameter(Mandatory=$true)]
		[string]
		$Configuration

	)

	$script:ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest

	Write-Verbose "Reading '$Configuration' config from '$Path'"

	[xml]$Project = Get-Content -Path $Path
	$Namespace = New-Object Xml.XmlNamespaceManager $Project.NameTable
	$Namespace.AddNamespace('ns', $Project.DocumentElement.NamespaceURI)

    $Config = $Project.SelectNodes('//ns:PropertyGroup', $Namespace) |
        Where-Object { $_.FullPath -eq $Configuration } |
        Select-Object -First 1

	if (-not $Config) {
		throw "Could not find configuration '$Configuration'."
	}


	$OverwriteDataSources = $false
	if ($Config.SelectSingleNode('ns:OverwriteDataSources', $Namespace)) {
		$OverwriteDataSources = [Convert]::ToBoolean($Config.OverwriteDataSources)
	}
	
	$OverwriteDatasets = $false
	if ($Config.SelectSingleNode('ns:OverwriteDatasets', $Namespace)) {
		$OverwriteDatasets = [Convert]::ToBoolean($Config.OverwriteDatasets)
	}
	

	return New-Object -TypeName PSObject -Property @{
		ServerUrl = $Config.TargetServerUrl
		Folder = Normalize-SSRSFolder -Folder $Config.TargetReportFolder
		DataSourceFolder = Normalize-SSRSFolder -Folder $Config.TargetDataSourceFolder
		DataSetFolder = Normalize-SSRSFolder -Folder $Config.TargetDataSetFolder
		OutputPath = $Config.OutputPath
		OverwriteDataSources = $OverwriteDataSources
		OverwriteDatasets = $OverwriteDatasets
	}

}
