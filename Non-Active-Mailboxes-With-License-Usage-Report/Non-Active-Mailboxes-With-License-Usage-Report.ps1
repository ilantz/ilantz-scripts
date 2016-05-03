<#

	.SYNOPSIS
    Non-Active-Mailboxes-With-License-Usage-Report
   
    Ilan Lanz
    http://ilantz.com
	
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
    Version 1.0, 17/07/2015
    
    .DESCRIPTION
    Report inactive mailboxes with applied licenses for Office 365.

			       
    Revision History
    --------------------------------------------------------------------------------
    1.0     Initial release
	
#>
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
 
 $colReport | Export-Csv -NoTypeInformation Non-Active-Mailboxes-With-License-Usage-Report.csv


