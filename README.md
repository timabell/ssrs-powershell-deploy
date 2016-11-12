# SSRS Powershell Deploy

* https://github.com/timabell/ssrs-powershell-deploy

PowerShell module to publish SQL Server Reporting Services project(s)
(`.rptproj`) to a Reporting Server

## Chat

[![Join the chat at https://gitter.im/ssrs-powershell-deploy/Lobby](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ssrs-powershell-deploy/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Wiki

There's a [project wiki on
github](https://github.com/timabell/ssrs-powershell-deploy/wiki), go ahead and
expand it 

## This fork

This repository was forked from:

* https://gist.github.com/Jonesie/9005796
	* which was forked from https://gist.github.com/ChrisMissal/5979564
		* which was forked from https://gist.github.com/jstangroome/3043878

I've turned it into a proper github repo to allow discussion, pull requests
etc.

## Installation

1. Download the .zip from
	 https://github.com/timabell/ssrs-powershell-deploy/releases/latest
2. Right-click the zip file in windows explorer, click "properties", and then
	 click "Unblock".
3. Create folder `Documents\WindowsPowerShell\Modules\`
4. Open up the zip file, copy the SSRS folder, paste it into
	 `Documents\WindowsPowerShell\Modules\`. (Or somewhere on your
	 `$env:PSModulePath`)

## Usage

	Publish-SSRSProject.ps1 -path YourReportsProject.rptproj -configuration Release -verbose

You can either specifiy a build configuration to read from the project file, or
you can specify all the information required to publish in the rest of the
parameters.

	Publish-SSRSProject [-Path] <string> [[-Configuration]
		<string>] [[-ServerUrl] <string>] [[-Folder] <string>]
		[[-DataSourceFolder] <string>] [[-DataSetFolder] <string>]
		[[-OutputPath] <string>] [[-OverwriteDataSources] <bool>]
		[[-OverwriteDatasets] <bool>] [[-Credential] <pscredential>]
		[<CommonParameters>]

## Example reports

To open the Example-Reports project in Visual Studio you'll need [Sql Server
Data Tools (SSDT)](https://msdn.microsoft.com/en-us/library/mt204009.aspx)

## General SSRS gotchas

Disappearing dataset panel -
http://stackoverflow.com/questions/7960824/i-lost-datasets-pane-in-visual-studio/28883272#28883272

VS report projects cache both datasets and data. Remove all the `.data` files and the
`bin/` folder(s) to be sure your changes will work when published.
http://stackoverflow.com/questions/3424928/in-ssrs-is-there-a-way-to-disable-the-rdl-data-file-creation

More SSRS love http://timwise.blogspot.co.uk/2015/08/100-reasons-i-hate-ssrs.html  <3 <3

## Development

Developed with [PowerShell Tools for Visual Studio 2015](https://visualstudiogallery.msdn.microsoft.com/c9eb3ba8-0c59-4944-9a62-6eee37294597)

To test the module locally directly from the source tree you can import by specifiying the path to the psd1 file.

	PS C:\repo\ReportDefinitions> Import-Module C:\repo\tim\ssrs-powershell-deploy\ssrs-powershell-deploy\SSRS\SSRS.psd1
	PS C:\repo\ReportDefinitions> Publish-SSRSProject

See the exported commands with

	PS C:\repo\ReportDefinitions> Get-Command -Module SSRS

	CommandType     Name                                               Version    Source
	-----------     ----                                               -------    ------
	Function        Publish-SSRSProject                                1.2.0      SSRS
	Function        Publish-SSRSSolution                               1.2.0      SSRS

Unload again with

	PS C:\repo\ReportDefinitions> Remove-Module SSRS
