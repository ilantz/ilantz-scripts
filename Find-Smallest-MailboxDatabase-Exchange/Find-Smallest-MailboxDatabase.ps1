<#

	.SYNOPSIS
    Find-Smallest-MailboxDatabase
   
    Ilan Lanz
    http://ilantz.com
	
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
    Version 1.0, 17/07/2015
    
    .DESCRIPTION
    A simple database report that can help detemine where to place a new mailbox.

			       
    Revision History
    --------------------------------------------------------------------------------
    1.0     Initial release
	
#>
# Works with Exchange 2010 and above..
# Use this example to exclude or include specific databases from the suggestion:   $dbs = Get-MailboxDatabase -Status | ? {$_.Name -ne "DB01" -AND $_.Name -ne "DB02" -AND $_.Name -like "DB*"} | select Name, DatabaseSize, AvailableNewMailboxSpace
$dbs = Get-MailboxDatabase -Status | select Name, DatabaseSize, AvailableNewMailboxSpace

$report = @()

foreach ($db in $dbs)
                {
                $dbObj = New-Object PSObject
                $dbObj | Add-Member NoteProperty -Name "Name" -Value $db.name
                $dbObj | Add-Member NoteProperty -Name "DatabaseSize" -Value $db.DatabaseSize
                $dbObj | Add-Member NoteProperty -Name "AvailableNewMailboxSpace" -Value $db.AvailableNewMailboxSpace
                $dbObj | Add-Member NoteProperty -Name "ActualSize" -Value ($db.DatabaseSize - $db.AvailableNewMailboxSpace)
                $dbObj | Add-Member NoteProperty -Name "MailboxCount" -Value (get-mailbox -Database $db.Name -ResultSize:unlimited).count
                $report = $report += $dbObj
                }

$report | Sort-Object -Property ActualSize,mailboxcount | Select-Object -First 1
