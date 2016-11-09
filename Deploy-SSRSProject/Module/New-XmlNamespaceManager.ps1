function New-XmlNamespaceManager ($XmlDocument, $DefaultNamespacePrefix) {

	$script:ErrorActionPreference = 'Stop'

	$NsMgr = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $XmlDocument.NameTable
	$DefaultNamespace = $XmlDocument.DocumentElement.GetAttribute('xmlns')
	if ($DefaultNamespace -and $DefaultNamespacePrefix) {
		$NsMgr.AddNamespace($DefaultNamespacePrefix, $DefaultNamespace)
	}
	return ,$NsMgr # unary comma wraps $NsMgr so it isn't unrolled
}
