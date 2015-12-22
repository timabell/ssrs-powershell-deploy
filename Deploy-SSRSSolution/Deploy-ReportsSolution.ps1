#requires -version 2.0
[CmdletBinding()]
# Path is the full path to the solution file, including the file name.
# i.e. D:\dev\Reports\Reports.sln
param (
    [parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]
    $Path
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Get credentials, interactive
$credentials = Get-Credential
# non-interactive
#$secpasswd = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
#$mycreds = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)

$Path = ($Path | Resolve-Path).ProviderPath

$SolutionRoot = $Path | Split-Path

# Guid is for the Reports project type.
$SolutionProjectPattern = @"
(?x)
^ Project \( " \{ F14B399A-7131-4C87-9E4B-1186C45EF12D \} " \)
\s* = \s*
" (?<name> [^"]* ) " , \s+
" (?<path> [^"]* ) " , \s+
"@

Get-Content -Path $Path |
    ForEach-Object {
        if ($_ -match $SolutionProjectPattern) {
            $ProjectPath = $SolutionRoot | Join-Path -ChildPath $Matches['path']
            $ProjectPath = ($ProjectPath | Resolve-Path).ProviderPath
            #"$ProjectPath" = full path to the project file
            
            $scriptPath = "..\Deploy-SSRSProject"
            # deploy
            & "$scriptPath\Deploy-SSRSProject.ps1" -path $ProjectPath -configuration Debug -verbose -credential $credentials
        }
    }