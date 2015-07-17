# Report inactive mailboxes with applied licenses 
$StaleMailboxes = Get-StaleMailboxDetailReport -StartDate 7/11/2015
$msolusers = get-msoluser -All

$ErrorActionPreference= 'silentlycontinue'
$colReport = @()
foreach ($mailbox in $StaleMailboxes)
  {
    $msolprop = $null
	$msolprop = $msolusers | ? {$_.UserPrincipalName -eq $mailbox.WindowsLiveID }
	
	$objMailbox = New-Object System.Object
    $objMailbox | Add-Member -type NoteProperty -name WindowsLiveID -value $mailbox.WindowsLiveID
	$objMailbox | Add-Member -type NoteProperty -name UserDisplayName -value $mailbox.UserName
	$objMailbox | Add-Member -type NoteProperty -name LastLogin -value $mailbox.LastLogin
	$objMailbox | Add-Member -type NoteProperty -name DaysInactive -value $mailbox.DaysInactive
	$objMailbox | Add-Member -type NoteProperty -name IsLicensed -value $msolprop.IsLicensed
	$objMailbox | Add-Member -type NoteProperty -name IsDisabledUser -value $msolprop.BlockCredential
	$objMailbox | Add-Member -type NoteProperty -name Licenses -value ([string]::join(";", ($msolprop.Licenses.AccountSkuId)))

	$colReport += $objMailbox
  }
 
 $colReport | Export-Csv -NoTypeInformation non-active-report.csv


