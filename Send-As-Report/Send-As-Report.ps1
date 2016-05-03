<#
.SYNOPSIS
    The script creates a report for recipients which have non-inherited Send-As permissions assigned.
.DESCRIPTION
    The script creates a report for recipients which have non-inherited Send-As permissions assigned.
	
	The script performs the following stpes to achieve the report:
		-	Gather all recipients to an array.
		-	Iterate thru each recipient and locate any recipient with a non-inherited Send-As permission.
		-	Expand the result and list back each entry and add it to the report.
	
	The report will exported to Send-As-Report.CSV
	Run the script from an Exchange Management Shell
	
.NOTES
    File Name: Send-As-Report.ps1
	Version: 0.3
	Version History:
		* 0.1 - initial release
		* 0.2 - fixed an exception with calculating the progress while reporting $delegatelist 
		* 0.3 - now filtering S-1-* to exclude any non-existing ACL entries 
	Last Update: 28/Feb/2016
	Author   : Ilan Lanz, http://ilantz.com
    The script is provided “AS IS” with no guarantees, no warranties, USE ON YOUR OWN RISK.    
#>

#### modify the query to narrow down the search, like a specific OU for example.
#
$recipients = Get-Recipient -resultsize:unlimited 
#
####

$report = @()
$i = 0
foreach ($recipient in $recipients)
{

$delegatelist = $null
$delegatelist = Get-ADPermission $recipient.identity | ? {$_.isinherited -ne $true -and $_.ExtendedRights -like "Send-as" -and $_.User -notlike "NT AUTHORITY\SELF" -and $_.User -notlike "S-1-*"}

	if ($delegatelist) 
	{
    $ii = 0
    foreach ($delegate in $delegatelist)
		{
		$delegateprops = [ADSI]"LDAP://$((Get-Recipient $delegate.user).DistinguishedName)"
        $userObj = New-Object PSObject
		$userObj | Add-Member NoteProperty -Name "Recipient" -Value $recipient.Identity
		$userObj | Add-Member NoteProperty -Name "RecipientType" -Value $recipient.RecipientType
		$userObj | Add-Member NoteProperty -Name "RecipientUPN" -Value (([ADSI]"LDAP://$($recipient.DistinguishedName)").userprincipalname).tostring()
		$userObj | Add-Member NoteProperty -Name "RecipientMail" -Value $recipient.PrimarySmtpAddress
		$userObj | Add-Member NoteProperty -Name "SendAsDelegate" -Value $delegate.User
		$userObj | Add-Member NoteProperty -Name "SendAsDelegateUPN" -Value ($delegateprops.userprincipalname).tostring()
		$userObj | Add-Member NoteProperty -Name "SendAsDelegateMail" -Value ($delegateprops.mail).tostring()
	
		$report = $report += $userObj
        $ii++
        Write-Progress -Id 1 -Activity "Found Send-As permissions assigned for $recipient" -status "Listing entry $ii out of $(($delegatelist | measure-object).count))" -percentComplete (($ii / ($delegatelist | measure-object).count)  * 100) -ErrorAction:SilentlyContinue
        }
        Write-Progress -Id 1 -Activity "Found Send-As permissions assigned for $recipient !" -status "Listing entry $ii out of $(($delegatelist | measure-object).count))" -Completed -ErrorAction:SilentlyContinue
	}
$i++
Write-Progress -Activity "Searching for recipients with non-inherited Send-As permissions..." -status "Proccessed $i of $($recipients.Count)" -percentComplete (($i / $recipients.Count)  * 100) -ErrorAction:SilentlyContinue
}

$report | Export-CSV -NoTypeInformation Send-As-Report.csv