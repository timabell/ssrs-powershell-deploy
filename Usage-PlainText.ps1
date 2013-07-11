$pass = ConvertTo-SecureString -AsPlainText -Force -String "password"
$user = "username"

$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $user,$pass

Write-Host "Deployment started..." -foregroundcolor yellow

.\Deploy-SSRSProject.ps1 -Verbose -Path 'pathtoproject\ProjectFile.rptproj' -Configuration 'Release' -Credential $cred

Write-Host "Deployment finished!" -foregroundcolor green
