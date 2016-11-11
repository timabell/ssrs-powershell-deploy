# About

https://github.com/timabell/ssrs-powershell-deploy

PowerShell module to publish SQL Server Reporting Services project(s)
(`.rptproj`) to a Reporting Server

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

# Downloads

Download a .zip or tarball from
https://github.com/timabell/ssrs-powershell-deploy/releases/latest - this will
be the current stable release. Note that this readme (in master) could be ahead
of the one in the latest stable release so check the usage info there to avoid
confusion. If you want the bleeding edge then
[download](https://github.com/timabell/ssrs-powershell-deploy/archive/master.zip)
or clone master.

# Usage

Copy the SSRS folder and paste it somewhere on your `$env:PSModulePath` e.g.
`C:\Users\tim\Documents\WindowsPowerShell\Modules\SSRS`.

	Import-Module SSRS -PassThru
	Get-Command -Module SSRS  # Run this to see available functions

	Publish-SSRSProject.ps1 -path YourReportsProject.rptproj -configuration Release -verbose

Full parameter list is defined at the top of
[Publish-SSRSProject.ps1](https://github.com/timabell/ssrs-powershell-deploy/blob/master/Publish-SSRSProject/Module/Publish-SSRSProject.ps1#L5)

If I understand it correctly (I didn't write it) you can specify either a build
configuration to read deployment settings from or you can specify all these
settings manually (`ParameterSetName='Target'`).

# Example reports

To open the example reports project in visual studio and edit the reports
you'll need [Sql Server Data Tools
(SSDT)](http://www.microsoft.com/en-us/download/details.aspx?id=42313)

See also
http://stackoverflow.com/questions/21351308/business-intelligence-ssdt-for-visual-studio-2013

## General SSRS gotchas

Disappearing dataset panel -
http://stackoverflow.com/questions/7960824/i-lost-datasets-pane-in-visual-studio/28883272#28883272

VS report projects cache both datasets and data. Remove all the `.data` files and the
`bin/` folder(s) to be sure your changes will work when published.
http://stackoverflow.com/questions/3424928/in-ssrs-is-there-a-way-to-disable-the-rdl-data-file-creation

More SSRS love http://timwise.blogspot.co.uk/2015/08/100-reasons-i-hate-ssrs.html  <3 <3

# Development

Developed with [PowerShell Tools for Visual Studio 2015](https://visualstudiogallery.msdn.microsoft.com/c9eb3ba8-0c59-4944-9a62-6eee37294597)
