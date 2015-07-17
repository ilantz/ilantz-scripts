# Searching all groups with ANY proxyAddresses values
$groups = Get-ADGroup -LDAPFilter "(&(objectCategory=group)(objectClass=group)(managedBy=*)(proxyAddresses=SMTP*))" -Properties ManagedBy, msExchCoManagedByLink,mail
# Extract group owners into a single Array
$owners = @()
foreach ($group in $groups) { 
	$owners += $group.ManagedBy
	$owners += $group.msExchCoManagedByLink
	}
# Filter only unique owners values
$uniquegroupowners = $owners.GetEnumerator() | select -Unique
# Build the report
$report = @()
foreach ($user in $uniquegroupowners) {
	$userprops = get-aduser -Identity ([string]$user) -Properties mail
	Write-Host "processing" $userprops.mail
	$managedgroups = @()
	Write-Host "processing groups..."
	foreach ($group in $groups) {
		if ($group.ManagedBy.Contains($user) -or $group.msExchCoManagedByLink.Contains($user)) { 
			$managedgroups += ($group.Name + " - " + $group.Mail)
			Write-Host $userprops.mail "is managing" $group.Name
		}
	}
	
	$rptObj = "" | Select UserMail, UserDN, ManagedGroups, NumberOfManagedGroups
	$rptObj.UserMail = $userprops.mail
	$rptObj.UserDN = $user
	$rptObj.ManagedGroups = ($managedgroups -join "`r`n" | Out-String)
	$rptObj.NumberOfManagedGroups = $managedgroups.count
	$report += $rptObj
	Write-Host $userprops.mail "is managing" $managedgroups.count "groups"
	}
$report | Export-Csv -NoTypeInformation -Encoding:UTF8 -Path Group-Owners-Report.csv
