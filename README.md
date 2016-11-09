#About

https://github.com/timabell/ssrs-powershell-deploy

PowerShell scripts to deploy a SQL Server Reporting Services project
(*.rptproj) to a Reporting Server

## wiki

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

# Downloads

Download a .zip or tarball from
https://github.com/timabell/ssrs-powershell-deploy/releases/latest - this will
be the current stable release.

# Usage

	.\Deploy-SSRSProject.ps1 -path YourReportsProject.rptproj -configuration Release -verbose

Full parameter list is defined at the top of
[Deploy-SSRSProject.ps1](https://github.com/timabell/ssrs-powershell-deploy/blob/master/Deploy-SSRSProject/Deploy-SSRSProject.ps1#L4)

If I understand it correctly (I didn't write it) you can specify either a build
configuration to read deployment settings from or you can specify all these
settings manually (`ParameterSetName='Target'`).

# Example reports

To open the example reports project in visual studio and edit the reports
you'll need [Sql Server Data Tools
(SSDT)](http://www.microsoft.com/en-us/download/details.aspx?id=42313)

See also
http://stackoverflow.com/questions/21351308/business-intelligence-ssdt-for-visual-studio-2013

## Gotchas

Disappearing dataset panel -
http://stackoverflow.com/questions/7960824/i-lost-datasets-pane-in-visual-studio/28883272#28883272

The project caches both datasets and data. Remove all the `.data` files and the
`bin/` folder(s) to be sure your changes will work when deployed.
http://stackoverflow.com/questions/3424928/in-ssrs-is-there-a-way-to-disable-the-rdl-data-file-creation

# Development

Developed with [PowerShell Tools for Visual Studio 2015](https://visualstudiogallery.msdn.microsoft.com/c9eb3ba8-0c59-4944-9a62-6eee37294597)
