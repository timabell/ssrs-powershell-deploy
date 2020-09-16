function New-SSRSFolder (
	$Proxy,
	[string]
	$Name,
	[switch]
	$Recursing
)
{
  $script:ErrorActionPreference = 'Stop'

	if (!$recursing) {
		Write-Verbose "Creating SSRS folder '$Name'"
	}

	$Name = Normalize-SSRSFolder -Folder $Name

	if ($Proxy.GetItemType($Name) -ne 'Folder') {
		$Parts = $Name -split '/'
		$Leaf = $Parts[-1]
		$Parent = $Parts[0..($Parts.Length-2)] -join '/'

		if ($Parent) {
			New-SSRSFolder -Proxy $Proxy -Name $Parent -Recursing
		} else {
			$Parent = '/'
		}

		# create folder, suppressing console output from proxy
		$Proxy.CreateFolder($Leaf, $Parent, $null) > $null
	} else {
		if (!$recursing) {
			Write-Verbose " - skipped, already exists"
		}
	}
	
	if($Name -eq '/Core' -or $Name -eq '/Client_Data')
	{
		Write-Verbose "Setting Policies for Subscribers..."

		$type = $Proxy.GetType().Namespace;
		$policyType = "{0}.Policy" -f $type;
		$roleType = "{0}.Role" -f $type;
		
		$InheritParent = $true
		$Policies = $Proxy.GetPolicies($Name, [ref]$InheritParent)

		$GroupUserName = 'Subscribers'
		$RoleName = 'Browser'

		#Return all policies that contain the user/group we want to add
		$Policy = $Policies | 
		    Where-Object { $_.GroupUserName -eq $GroupUserName } | 
		    Select-Object -First 1
		#Add a new policy if doesnt exist
		if (-not $Policy) 
		{
		    $Policy = New-Object ($policyType)
		    $Policy.GroupUserName = $GroupUserName
		    $Policy.Roles = @()
			#Add new policy to the folder's policies
		    $Policies += $Policy
		}
		#Add the role to the new Policy
		$r = $Policy.Roles |
	        Where-Object { $_.Name -eq $RoleName } |
	        Select-Object -First 1
	    	if (-not $r) 
		{
	        	$r = New-Object ($roleType)
	        	$r.Name = $RoleName
	        	$Policy.Roles += $r
    		}
		
		#Set folder policies
		$Proxy.SetPolicies($Name, $Policies);
	}
}
