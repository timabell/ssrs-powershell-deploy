function Publish-SSRSProject{
	#requires -version 2.0
	# https://github.com/timabell/ssrs-powershell-deploy
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$true)]
		[ValidatePattern('\.rptproj$')]
		[ValidateScript({ Test-Path -PathType Leaf -Path $_ })]
		[string]
		$Path,

		[parameter(Mandatory=$false)]
		[string]
		$Configuration,

		[parameter(Mandatory=$false)]
		[ValidatePattern('^https?://')]
		[string]
		$ServerUrl, #THESE ARE NOW OVERRRIDES IF $Configuration is specified

		[parameter(Mandatory=$false)]
		[string]
		$Folder, #THESE ARE NOW OVERRRIDES IF $Configuration is specified

		[parameter(Mandatory=$false)]
		[string]
		$DataSourceFolder, #THESE ARE NOW OVERRRIDES IF $Configuration is specified

		[parameter(Mandatory=$false)]
		[string]
		$DataSetFolder, #THESE ARE NOW OVERRRIDES IF $Configuration is specified

		[parameter(Mandatory=$false)]
		[string]
		$OutputPath, #THESE ARE NOW OVERRRIDES IF $Configuration is specified

		[parameter(Mandatory=$false)]
		[bool]
		$OverwriteDataSources, #THESE ARE NOW OVERRRIDES IF $Configuration is specified

		[parameter(Mandatory=$false)]
		[bool]
		$OverwriteDatasets, #THESE ARE NOW OVERRRIDES IF $Configuration is specified

		[System.Management.Automation.PSCredential]
		$Credential,

		[parameter(Mandatory=$false)]
		[switch]
		$CustomAuthentication
	)


	$script:ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest

	$Path = $Path | Convert-Path
	$ProjectRoot = $Path | Split-Path
	[xml]$Project = Get-Content -Path $Path

	$Namespace = New-Object Xml.XmlNamespaceManager $Project.NameTable
	$Namespace.AddNamespace('ns', $Project.DocumentElement.NamespaceURI)

	#Argument validation
	if(![string]::IsNullOrEmpty($Configuration))
	{
		$Config = Get-SSRSProjectConfiguration -Path $Path -Configuration $Configuration

		if([string]::IsNullOrEmpty($ServerUrl))
		{
			Write-Verbose "Using Project Server URL: $($Config.ServerUrl)"
			$ServerUrl = $Config.ServerUrl
		}

		if([string]::IsNullOrEmpty($Folder))
		{
			Write-Verbose "Using Project Folder : $($Config.Folder)"
			$Folder = $Config.Folder
		}

		if([string]::IsNullOrEmpty($DataSourceFolder))
		{
			Write-Verbose "Using Project DataSourceFolder: $($Config.DataSourceFolder)"
			$DataSourceFolder = $Config.DataSourceFolder
		}

		if([string]::IsNullOrEmpty($DataSetFolder))
		{
			Write-Verbose "Using Project DataSetFolder: $($Config.DataSetFolder)"
			$DataSetFolder = $Config.DataSetFolder
		}

		if([string]::IsNullOrEmpty($OutputPath))
		{
			Write-Verbose "Using Project OutputPath: $($Config.OutputPath)"
			$OutputPath = $Config.OutputPath
		}

		if(!$PSBoundParameters.ContainsKey("OverwriteDataSources"))
		{
			Write-Verbose "Using Project OverwriteDataSources: $($Config.OverwriteDataSources)"
			$OverwriteDataSources = $Config.OverwriteDataSources
		}

		if(!$PSBoundParameters.ContainsKey("OverwriteDatasets"))
		{
			Write-Verbose "Using Project OverwriteDatasets: $($Config.OverwriteDatasets)"
			$OverwriteDatasets = $Config.OverwriteDatasets
		}


	}

	$Project.SelectNodes('//ns:Report', $Namespace) |
		ForEach-Object {
			$Name = $_.Include
			$CompiledRdlPath = $ProjectRoot | Join-Path -ChildPath $OutputPath | join-path -ChildPath $Name
			$RdlPath = $ProjectRoot | join-path -ChildPath $Name
		
			if ((test-path $CompiledRdlPath) -eq $false)
			{
				write-error ('Report "{0}" is listed in the project but wasn''t found in the bin\ folder. Rebuild your project before publishing.' -f $CompiledRdlPath)
				break;
			}
			$RdlLastModified = (get-item $RdlPath).LastWriteTime
			$CompiledRdlLastModified = (get-item $CompiledRdlPath).LastWriteTime
			if ($RdlLastModified -gt $CompiledRdlLastModified)
			{
				write-error ('Report "{0}" in bin\ is older than source file "{1}". Rebuild your project before publishing.' -f $CompiledRdlPath,$RdlPath)
				break;
			}
		}


	$Folder = Normalize-SSRSFolder -Folder $Folder
	$DataSourceFolder = Normalize-SSRSFolder -Folder $DataSourceFolder

	$ProxyParameters = @{
		Uri = $ServerUrl
		Credential = $Credential
		CustomAuthentication = $CustomAuthentication
	}

	Write-Verbose "Connecting to: $ServerUrl"

	$Proxy = New-SSRSWebServiceProxy @ProxyParameters
	$FullServerPath = $Proxy.Url

	New-SSRSFolder -Proxy $Proxy -Name $Folder
	New-SSRSFolder -Proxy $Proxy -Name $DataSourceFolder
	New-SSRSFolder -Proxy $Proxy -Name $DataSetFolder

	$DataSourcePaths = @{}
	$Project.SelectNodes('//ns:DataSource', $Namespace) |
		ForEach-Object {
			$Name = $_.Include
			$RdsPath = $ProjectRoot | Join-Path -ChildPath $Name

			$DataSource = New-SSRSDataSource -Proxy $Proxy -RdsPath $RdsPath -Folder $DataSourceFolder -Overwrite $OverwriteDataSources
			$DataSourcePaths.Add($DataSource.Name, $DataSource.Path)
		}

	$DataSetPaths = @{}
	$Project.SelectNodes('//ns:DataSet', $Namespace) |
		ForEach-Object {
			$Name = $_.Include
			$RsdPath = $ProjectRoot | Join-Path -ChildPath $Name
			$DataSet = New-SSRSDataSet -Proxy $Proxy -RsdPath $RsdPath -Folder $DataSetFolder -DataSourcePaths $DataSourcePaths -Overwrite $OverwriteDatasets
			if(-not $DataSetPaths.Contains($DataSet.Name))
			{
				$DataSetPaths.Add($DataSet.Name, $DataSet.Path)
			}
		}

	$Project.SelectNodes('//ns:Report', $Namespace) |
		ForEach-Object {
			$Name = $_.Include
			$MimeType = $_.SelectSingleNode('ns:MimeType', $Namespace)

			if($MimeType){

				$PathImage = $ProjectRoot | Join-Path -ChildPath $Name
				$RawDefinition = Get-Content -Encoding Byte -Path $PathImage

				$DescProp = New-Object -TypeName SSRS.ReportingService2010.Property
				$DescProp.Name = 'Description'
				$DescProp.Value = ''
				$HiddenProp = New-Object -TypeName SSRS.ReportingService2010.Property
				$HiddenProp.Name = 'Hidden'
				$HiddenProp.Value = 'false'
				$MimeProp = New-Object -TypeName SSRS.ReportingService2010.Property
				$MimeProp.Name = 'MimeType'
				$MimeProp.Value = $MimeType

				$Properties = @($DescProp, $HiddenProp, $MimeProp)

				$Name = $Name
				Write-Verbose "Creating resource $Name"
				$warnings = $null
				$Results = $Proxy.CreateCatalogItem("Resource", $Name, $Folder, $true, $RawDefinition, $Properties, [ref]$warnings)
			}
		
			if($Name.EndsWith('.rdl')){
				$CompiledRdlPath = $ProjectRoot | Join-Path -ChildPath $OutputPath | join-path -ChildPath $Name
				New-SSRSReport -Proxy $Proxy -RdlPath $CompiledRdlPath -RdlName $Name
			}
		}

	Write-host "Completed: $Path"
}
