
$pass = "password"
$user = "username"

Import-Module .\Module\SSRS.psm1

Write-Host "Publish started..." -foregroundcolor yellow
$cred=Get-SSRSCredential -username $user -password $pass
Publish-SSRSProject -Verbose -Path 'pathtoproject\ProjectFile.rptproj' -Configuration 'Release' -Credential $cred

Write-Host "Publish finished!" -foregroundcolor green
