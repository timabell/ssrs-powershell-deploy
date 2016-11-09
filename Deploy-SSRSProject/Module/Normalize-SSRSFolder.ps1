function Normalize-SSRSFolder (
	[string]$Folder
) 
{
  $script:ErrorActionPreference = 'Stop'
	if (-not $Folder.StartsWith('/')) {
		$Folder = '/' + $Folder
	}

	return $Folder
}