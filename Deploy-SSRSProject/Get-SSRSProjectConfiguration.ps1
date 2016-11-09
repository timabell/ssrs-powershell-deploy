﻿#requires -version 2.0
function Get-SSRSProjectConfiguration {
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

	$Config = $Project.SelectNodes('Project/Configurations/Configuration') |
		Where-Object { $_.Name -eq $Configuration } |
		Select-Object -First 1
	if (-not $Config) {
		throw "Could not find configuration $Configuration."
	}


	$OverwriteDataSources = $false
	if ($Config.Options.SelectSingleNode('OverwriteDataSources')) {
		$OverwriteDataSources = [Convert]::ToBoolean($Config.Options.OverwriteDataSources)
	}

	return New-Object -TypeName PSObject -Property @{
		ServerUrl = $Config.Options.TargetServerUrl
		Folder = Normalize-SSRSFolder -Folder $Config.Options.TargetFolder
		DataSourceFolder = Normalize-SSRSFolder -Folder $Config.Options.TargetDataSourceFolder
		DataSetFolder = Normalize-SSRSFolder -Folder $Config.Options.TargetDataSetFolder
		OverwriteDataSources = $OverwriteDataSources
	}
}

function Normalize-SSRSFolder (
	[string]$Folder
) {
	if (-not $Folder.StartsWith('/')) {
		$Folder = '/' + $Folder
	}

	return $Folder
}
