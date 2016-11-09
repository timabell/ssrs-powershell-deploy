function Normalize-SSRSFolder (
	[string]$Folder
)
{
	$script:ErrorActionPreference = 'Stop'
	if (-not $Folder.StartsWith('/')) {
		$Folder = '/' + $Folder
	}

	if($Folder.EndsWith('/')) {
		$Folder = $Folder.Substring(0, $Folder.Length -1)
	}

	return $Folder
}
