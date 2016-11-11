Function Get-SSRSCredential
{
	[CmdletBinding(SupportsShouldProcess=$true)]
	param
	(
	[string] $username,
	[string] $password
	)

	$script:ErrorActionPreference = 'Stop'

	$pass = ConvertTo-SecureString -AsPlainText -Force -String $password
	$user = $username

	$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $user,$pass
	return $cred
}
