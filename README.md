#About

https://github.com/timabell/ssrs-powershell-deploy

PowerShell scripts to deploy a SQL Server Reporting Services project (*.rptproj) to a Reporting Server

## wiki

There's a [project wiki on github](https://github.com/timabell/ssrs-powershell-deploy/wiki), go ahead and expand it 

## This fork

This repository was forked created from

* https://gist.github.com/Jonesie/9005796
	* fordked from https://gist.github.com/ChrisMissal/5979564
		* forked from https://gist.github.com/jstangroome/3043878

I've turned it into a proper github repo to allow discussion, pull requests etc.

# Downloads

Download a .zip or tarball from https://github.com/timabell/ssrs-powershell-deploy/releases/latest - this will be the current stable release.

# Usage

	.\Deploy-SSRSProject.ps1 -path YourReportsProject.rptproj -configuration Release -verbose
