if (-not (Test-Path("cred2.txt"))) {
	Write-Host "=========================================================" -foregroundcolor cyan
	Write-Host "» To deploy the Debug configuration to localhost, type"
	Write-Host "» your credentials. It will be stored as a SecureString"
	Write-Host "» on disk, but not checked into source control."
	Write-Host "» Username: " -foregroundcolor cyan; Read-Host | Out-File cred1.txt
	Write-Host "» Password: " -foregroundcolor cyan; Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File cred2.txt
}

$pass = cat cred2.txt | ConvertTo-SecureString
$user = cat cred1.txt
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $user,$pass

Write-Host "Deployment started..." -foregroundcolor yellow

Import-Module .\Module\SSRS.psm1

Deploy-SSRSProject -Path 'pathtoproject\ProjectFile.rptproj' -Configuration 'Debug' -Credential $cred

Write-Host "Deployment finished!" -foregroundcolor green
