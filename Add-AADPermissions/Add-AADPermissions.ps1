<#

	.SYNOPSIS
    Add-AADPermissions
   
    Ilan Lanz
    http://ilantz.com
	
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
    Version 1.0, 09/02/2016
    
    .DESCRIPTION
    This script will add the required AD ACL's to support Azure AD Connect aka AADSync aka DirSync aka Directory Synchronization.
    Based on the works by Simon Waight @ http://blog.kloud.com.au/2014/12/18/aadsync-ad-service-account-delegated-permissions/

			       
    Revision History
    --------------------------------------------------------------------------------
    1.0     Initial release
	
    .PARAMETER ServiceAccount
    The username of the local Active Directory AD Connect service account
	
    .EXAMPLE
    Add-AADPermissions -ServiceAccount svc-dirsync
    This will add the required permissions for the service account "svc-dirsync"
#>
[cmdletbinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High"
    )]
param(
	[Parameter(Mandatory=$true)]
		[string]$ServiceAccount = "Read-Host -Prompt `"Enter the service account username (samAccountname):`""
	)

process {
        
    # Logging global settings and function
    $LogFileName = "Add-AADPermissions"
    $LogFile  = $home + "\" + (Get-Date -uformat "%Y-%m-%d__%H-%M-%S") + "_" + $LogFileName + ".log"

    function writelog([string]$value = ""){
    $LogDate = Get-Date -uformat "%Y %m-%d %H:%M:%S"
    $LogOutput = ("$LogDate $value")
    Out-File -InputObject:$LogOutput -FilePath:$LogFile -Append:$True -Encoding:UTF8; 
    Write-Host $LogOutput
    }

    #Write the first report line to check for logging feasibility
    try
    {
    writelog ($LogFileName + " starting.")
    }
    catch
    {
    #Output the error to screen and exit
    Write-Host "Error writing to log, quitting..." -ForegroundColor:Red;
    Exit -1;
    }	
        
	function Add-AADPermissions ($ServiceAccount)
	{
	try
		{
		$DomainDN = [adsi]"" 
		$DomainDN = $DomainDN.distinguishedName
		$AdminSDHolderDN = "CN=AdminSDHolder,CN=System," + $DomainDN
		}
	catch
		{
		writelog ("Failed to query AD for the domain DN value, make sure you run this from a domain joined machine, and have domain admin rights")
		Exit -1
        }
    try
        {
        $cmd = "dsacls"
	    Invoke-Expression $cmd | Out-Null
        }
    catch
        {
        writelog ("Failed to run ICACLS, this script requires the Active Directory RSAT tools installed")
        Exit -1
        }

	writelog ("Adding Hybrid Exchange permissions")

	###---Update Attributes 
	#Object type: user 
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;proxyAddresses;user'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;msExchUCVoiceMailSettings;user'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;msExchUserHoldPolicies;user'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;msExchArchiveStatus;user'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;msExchSafeSendersHash;user'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;msExchBlockedSendersHash;user'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;msExchSafeRecipientsHash;user'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;msDS-ExternalDirectoryObject;user'"
	Invoke-Expression $cmd | Out-Null

	#Adding AdminSDHolder permissions
	$cmd = "dsacls '$AdminSDholderDN' /G '`"$Account`":WP;proxyAddresses'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$AdminSDholderDN' /G '`"$Account`":WP;msExchUCVoiceMailSettings'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$AdminSDholderDN' /G '`"$Account`":WP;msExchUserHoldPolicies'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$AdminSDholderDN' /G '`"$Account`":WP;msExchArchiveStatus'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$AdminSDholderDN' /G '`"$Account`":WP;msExchSafeSendersHash'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$AdminSDholderDN' /G '`"$Account`":WP;msExchBlockedSendersHash'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$AdminSDholderDN' /G '`"$Account`":WP;msExchSafeRecipientsHash'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$AdminSDholderDN' /G '`"$Account`":WP;msDS-ExternalDirectoryObject'"
	Invoke-Expression $cmd | Out-Null


	#Object type: group
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;proxyAddresses;group'"
	Invoke-Expression $cmd | Out-Null
	#Object type: contact 

	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;proxyAddresses;contact'"
	Invoke-Expression $cmd | Out-Null 

	writelog ("Adding Password Write-back permissions")

	###---Update Attributes
	#Object type: user
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":CA;`"Reset Password`";user'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":CA;`"Change Password`";user'"
	Invoke-Expression $cmd | Out-Null 

	writelog ("Adding Password Synchronization permissions")

	###---Update Attributes
	#Object type: user
	$cmd = "dsacls '$DomainDN' /G '`"$Account`":CA;`"Replicating Directory Changes`";'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /G '`"$Account`":CA;`"Replicating Directory Changes All`";'"
	Invoke-Expression $cmd | Out-Null 

	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;lockoutTime;user'"
	Invoke-Expression $cmd | Out-Null
	$cmd = "dsacls '$DomainDN' /I:S /G '`"$Account`":WP;pwdLastSet;user'"
	Invoke-Expression $cmd | Out-Null

    writelog ("Finished processing !")
    }
	

    ## Main Script Block
	$title = "Confirmation"
    $message = ("You entered " + $ServiceAccount + " as you service account name" + "`nThis will result in adding the permissions to the account:" + "`n" + $env:USERDOMAIN + "\" + $ServiceAccount)

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Continue with the script. The account name is correct."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "Stop and exit, the account name is incorrect"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 
			    { Write-Host -ForegroundColor Green "Proceeding with the script"
			    Write-Host -ForegroundColor Yellow "Log file will be created at" $home
			    $ServiceAccount = $env:USERDOMAIN + "\" + $ServiceAccount
                Add-AADPermissions $ServiceAccount
			    }
            1
			    {Write-Host -ForegroundColor Red "Exiting script..."
			    Exit -1
			    }
        }
}
