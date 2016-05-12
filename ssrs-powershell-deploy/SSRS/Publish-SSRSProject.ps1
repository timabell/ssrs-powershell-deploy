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
		$Credential
	)


	$script:ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest

	$Path = $Path | Convert-Path
	$ProjectRoot = $Path | Split-Path
	[xml]$Project = Get-Content -Path $Path



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


	$Folder = Normalize-SSRSFolder -Folder $Folder
	$DataSourceFolder = Normalize-SSRSFolder -Folder $DataSourceFolder

	$Proxy = New-SSRSWebServiceProxy -Uri $ServerUrl -Credential $Credential

	$FullServerPath = $Proxy.Url
	Write-Verbose "Connecting to: $FullServerPath"

	New-SSRSFolder -Proxy $Proxy -Name $Folder
	New-SSRSFolder -Proxy $Proxy -Name $DataSourceFolder
	New-SSRSFolder -Proxy $Proxy -Name $DataSetFolder

	$DataSourcePaths = @{}
	$Project.SelectNodes('Project/DataSources/ProjectItem') |
		ForEach-Object {
			$RdsPath = $ProjectRoot | Join-Path -ChildPath $_.FullPath

			$DataSource = New-SSRSDataSource -Proxy $Proxy -RdsPath $RdsPath -Folder $DataSourceFolder -Overwrite $OverwriteDataSources
			$DataSourcePaths.Add($DataSource.Name, $DataSource.Path)
		}

	$DataSetPaths = @{}
	$Project.SelectNodes('Project/DataSets/ProjectItem') |
		ForEach-Object {
			$RsdPath = $ProjectRoot | Join-Path -ChildPath $_.FullPath
			$DataSet = New-SSRSDataSet -Proxy $Proxy -RsdPath $RsdPath -Folder $DataSetFolder -DataSourcePaths $DataSourcePaths -Overwrite $OverwriteDatasets
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
			$CompiledRdlPath = $ProjectRoot | Join-Path -ChildPath $OutputPath | join-path -ChildPath $_.FullPath
			$RdlPath = $ProjectRoot | join-path -ChildPath $_.FullPath
		
			if ((test-path $CompiledRdlPath) -eq $false)
			{
				write-error ('File {0} not found. Build your project before deploying.' -f $CompiledRdlPath)
				break;
			}
			$RdlLastModified = (get-item $RdlPath).LastWriteTime
			$CompiledRdlLastModified = (get-item $CompiledRdlPath).LastWriteTime
			if ($RdlLastModified -gt $CompiledRdlLastModified)
			{
				#warning about to publish older report
				write-error ('File {0} is older than source file {1}. Rebuild your project before publishing.' -f $CompiledRdlPath,$RdlPath)
				break;
			}

			New-SSRSReport -Proxy $Proxy -RdlPath $CompiledRdlPath
		}

	Write-host "Completed."
}
