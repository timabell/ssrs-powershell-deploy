
$pass = "password"
$user = "username"

Import-Module .\Module\SSRS.psm1

Write-Host "Deployment started..." -foregroundcolor yellow
$cred=Get-SSRSCredential -username $user -password $pass
Deploy-SSRSProject -Verbose -Path 'pathtoproject\ProjectFile.rptproj' -Configuration 'Release' -Credential $cred

Write-Host "Deployment finished!" -foregroundcolor green
