#requires -version 2.0
# https://github.com/timabell/ssrs-powershell-deploy
[CmdletBinding()]
param (
	[parameter(Mandatory=$true)]
	[ValidatePattern('\.rptproj$')]
	[ValidateScript({ Test-Path -PathType Leaf -Path $_ })]
	[string]
	$Path,

	[parameter(
		ParameterSetName='Configuration',
		Mandatory=$true)]
	[string]
	$Configuration,

	[parameter(
		ParameterSetName='Target',
		Mandatory=$true)]
	[ValidatePattern('^https?://')]
	[string]
	$ServerUrl,

	[parameter(
		ParameterSetName='Target',
		Mandatory=$true)]
	[string]
	$Folder,

	[parameter(
		ParameterSetName='Target',
		Mandatory=$true)]
	[string]
	$DataSourceFolder,

	[parameter(
		ParameterSetName='Target',
		Mandatory=$true)]
	[string]
	$DataSetFolder,

	[parameter(ParameterSetName='Target')]
	[switch]
	$OverwriteDataSources,

	[System.Management.Automation.PSCredential]
	$Credential
)

function New-XmlNamespaceManager ($XmlDocument, $DefaultNamespacePrefix) {
	$NsMgr = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $XmlDocument.NameTable
	$DefaultNamespace = $XmlDocument.DocumentElement.GetAttribute('xmlns')
	if ($DefaultNamespace -and $DefaultNamespacePrefix) {
		$NsMgr.AddNamespace($DefaultNamespacePrefix, $DefaultNamespace)
	}
	return ,$NsMgr # unary comma wraps $NsMgr so it isn't unrolled
}

function Normalize-SSRSFolder (
	[string]$Folder
) {
	if (-not $Folder.StartsWith('/')) {
		$Folder = '/' + $Folder
	}

	return $Folder
}

function New-SSRSFolder (
	$Proxy,
	[string]
	$Name,
	[switch]
	$Recursing
) {
	if (!$recursing) {
		Write-Verbose "Creating SSRS folder '$Name'"
	}

	$Name = Normalize-SSRSFolder -Folder $Name

	if ($Proxy.GetItemType($Name) -ne 'Folder') {
		$Parts = $Name -split '/'
		$Leaf = $Parts[-1]
		$Parent = $Parts[0..($Parts.Length-2)] -join '/'

		if ($Parent) {
			New-SSRSFolder -Proxy $Proxy -Name $Parent -Recursing
		} else {
			$Parent = '/'
		}

		# create folder, suppressing console output from proxy
		$Proxy.CreateFolder($Leaf, $Parent, $null) > $null
	} else {
		if (!$recursing) {
			Write-Verbose " - skipped, already exists"
		}
	}
}

function New-SSRSDataSource (
	$Proxy,
	[string]$RdsPath,
	[string]$Folder,
	[switch]$Overwrite
) {
	Write-Verbose "Processing DataSource '$RdsPath'..."

	$Folder = Normalize-SSRSFolder -Folder $Folder

	[xml]$Rds = Get-Content -Path $RdsPath
	$ConnProps = $Rds.RptDataSource.ConnectionProperties

	$Definition = New-Object -TypeName SSRS.ReportingService2010.DataSourceDefinition
	$Definition.ConnectString = $ConnProps.ConnectString
	$Definition.Extension = $ConnProps.Extension
	if ([Convert]::ToBoolean($ConnProps.IntegratedSecurity)) {
		$Definition.CredentialRetrieval = 'Integrated'
	}

	$DataSource = New-Object -TypeName PSObject -Property @{
		Name = $Rds.RptDataSource.Name
		Path =  $Folder + '/' + $Rds.RptDataSource.Name
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

function New-SSRSDataSet (
	$Proxy,
	[string]$RsdPath,
	[string]$Folder,
	[switch]$Overwrite,
	$DataSourcePaths
) {
	Write-Verbose "Processing DataSet '$RsdPath'..."

	$Folder = Normalize-SSRSFolder -Folder $Folder

	$Name =  [System.IO.Path]::GetFileNameWithoutExtension($RsdPath)
	$RawDefinition = Get-Content -Encoding Byte -Path $RsdPath
	$overwrite = $true
	$properties = $null
	$warnings = $null

	# https://msdn.microsoft.com/en-us/library/reportservice2010.reportingservice2010.createcatalogitem.aspx
	$Results = $Proxy.CreateCatalogItem("DataSet", $Name, $Folder, $overwrite, $RawDefinition, $properties, [ref]$warnings)

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

function New-SSRSReport (
	$Proxy,
	[string]$RdlPath
) {
	[xml]$Definition = Get-Content -Path $RdlPath
	$NsMgr = New-XmlNamespaceManager $Definition d

	$RawDefinition = Get-Content -Encoding Byte -Path $RdlPath

	$Name = $_.Name -replace '\.rdl$',''

	$DescProp = New-Object -TypeName SSRS.ReportingService2010.Property
	$DescProp.Name = 'Description'
	$DescProp.Value = ''
	$HiddenProp = New-Object -TypeName SSRS.ReportingService2010.Property
	$HiddenProp.Name = 'Hidden'
	$HiddenProp.Value = 'false'
	$Properties = @($DescProp, $HiddenProp)

	$Xpath = 'd:Report/d:Description'
	$DescriptionNode = $Definition.SelectSingleNode($Xpath, $NsMgr)

	if($DescriptionNode)
	{
		$DescProp.Value = $DescriptionNode.Value
	}

	if($Name.StartsWith('_'))
	{
		$HiddenProp.Value = 'true'
	}

	Write-Verbose "Creating report $Name"
	$warnings = $null
	$Results = $Proxy.CreateCatalogItem("Report", $Name, $Folder, $true, $RawDefinition, $Properties, [ref]$warnings)

	$Xpath = 'd:Report/d:DataSources/d:DataSource/d:DataSourceReference/..'
	$DataSources = $Definition.SelectNodes($Xpath, $NsMgr) |
		ForEach-Object {
			$DataSourcePath = $DataSourcePaths[$_.DataSourceReference]
			if (-not $DataSourcePath) {
				throw "Invalid data source reference '$($_.DataSourceReference)' in $RdlPath"
			}
			$Reference = New-Object -TypeName SSRS.ReportingService2010.DataSourceReference
			$Reference.Reference = $DataSourcePath
			$DataSource = New-Object -TypeName SSRS.ReportingService2010.DataSource
			$DataSource.Item = $Reference
			$DataSource.Name = $_.Name
		}
	if ($DataSources) {
		$Proxy.SetItemDataSources($Folder + '/' + $Name, $DataSources)
	}

	$Xpath = 'd:Report/d:DataSets/d:DataSet/d:SharedDataSet/d:SharedDataSetReference/../..'
	$References = $Definition.SelectNodes($Xpath, $NsMgr) |
		ForEach-Object {
			$DataSetPath = $DataSetPaths[$_.SharedDataSet.SharedDataSetReference]
			if ($DataSetPath) {
				$Reference = New-Object -TypeName SSRS.ReportingService2010.ItemReference
				$Reference.Reference = $DataSetPath
				$Reference.Name = $_.Name
			}
		}
	if ($References) {
		$Proxy.SetItemReferences($Folder + '/' + $Name, $References)
	}
}

$script:ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$PSScriptRoot = $MyInvocation.MyCommand.Path | Split-Path

$Path = $Path | Convert-Path
$ProjectRoot = $Path | Split-Path
[xml]$Project = Get-Content -Path $Path

if ($PSCmdlet.ParameterSetName -eq 'Configuration') {
	$Config = & $PSScriptRoot\Get-SSRSProjectConfiguration.ps1 -Path $Path -Configuration $Configuration
	$ServerUrl = $Config.ServerUrl
	$Folder = $Config.Folder
	$DataSourceFolder = $Config.DataSourceFolder
	$DataSetFolder = $Config.DataSetFolder
	$OverwriteDataSources = $Config.OverwriteDataSources
}

$Folder = Normalize-SSRSFolder -Folder $Folder
$DataSourceFolder = Normalize-SSRSFolder -Folder $DataSourceFolder

$Proxy = & $PSScriptRoot\New-SSRSWebServiceProxy.ps1 -Uri $ServerUrl -Credential $Credential

New-SSRSFolder -Proxy $Proxy -Name $Folder
New-SSRSFolder -Proxy $Proxy -Name $DataSourceFolder
New-SSRSFolder -Proxy $Proxy -Name $DataSetFolder

$DataSourcePaths = @{}
$Project.SelectNodes('Project/DataSources/ProjectItem') |
	ForEach-Object {
		$RdsPath = $ProjectRoot | Join-Path -ChildPath $_.FullPath
		$DataSource = New-SSRSDataSource -Proxy $Proxy -RdsPath $RdsPath -Folder $DataSourceFolder
		$DataSourcePaths.Add($DataSource.Name, $DataSource.Path)
	}

$DataSetPaths = @{}
$Project.SelectNodes('Project/DataSets/ProjectItem') |
	ForEach-Object {
		$RsdPath = $ProjectRoot | Join-Path -ChildPath $_.FullPath
		$DataSet = New-SSRSDataSet -Proxy $Proxy -RsdPath $RsdPath -Folder $DataSetFolder -DataSourcePaths $DataSourcePaths
		if(-not $DataSetPaths.Contains($DataSet.Name))
		{
			$DataSetPaths.Add($DataSet.Name, $DataSet.Path)
		}
	}

$Project.SelectNodes('Project/Reports/ResourceProjectItem') |
	ForEach-Object {
		if($_.MimeType.StartsWith('image/'))
		{

			$Path = $ProjectRoot | Join-Path -ChildPath $_.FullPath
			$RawDefinition = Get-Content -Encoding Byte -Path $Path

			$DescProp = New-Object -TypeName SSRS.ReportingService2010.Property
			$DescProp.Name = 'Description'
			$DescProp.Value = ''
			$HiddenProp = New-Object -TypeName SSRS.ReportingService2010.Property
			$HiddenProp.Name = 'Hidden'
			$HiddenProp.Value = 'false'
			$MimeProp = New-Object -TypeName SSRS.ReportingService2010.Property
			$MimeProp.Name = 'MimeType'
			$MimeProp.Value = $_.MimeType

			$Properties = @($DescProp, $HiddenProp, $MimeProp)

			if($_.FullPath.StartsWith('_'))
			{
				$HiddenProp.Value = 'true'
			}

			$Name = $_.FullPath
			Write-Verbose "Creating resource $Name"
			$warnings = $null
			$Results = $Proxy.CreateCatalogItem("Resource", $_.FullPath, $Folder, $true, $RawDefinition, $Properties, [ref]$warnings)
		}
	}

$Project.SelectNodes('Project/Reports/ProjectItem') |
	ForEach-Object {
		$RdlPath = $ProjectRoot | Join-Path -ChildPath $_.FullPath
		New-SSRSReport -Proxy $Proxy -RdlPath $RdlPath
	}
