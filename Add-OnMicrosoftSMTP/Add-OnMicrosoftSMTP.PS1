<#

	.SYNOPSIS
    Add-OnMicrosoftSMTP
   
    Ilan Lanz
    http://ilantz.com
	
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
    Version 1.3, 05/02/2015
    
    .DESCRIPTION
    This script will find mailboxes that are configured with EmailAddressPolicyEnabled:$false
	and will add the SMTP routing address required for an Exchange Online Hybrid deployment. 
    The script tries to add the proxy address alias@tenant.mail.onmicrosoft.com to the each mailbox found.
    If that address is already being used, it will add a random number to the alias and adds that smtp address.
	       
    Revision History
    --------------------------------------------------------------------------------
    1.0     Initial release
	1.1 	Updated and rewritten as a script instead of a function which caused confusion.
	1.2		Added Logging of succesfull addresses being added and failures.
    1.3     Updated with server-side filtering to get all relevant users for better efficiency,
            an updated logging mechanism and using now the PrimarySmtpAddress prefix value for the routing address.
    
    .PARAMETER Tenant
    The name of the Office 365 tenant - without the .onmicrosoft.com
	For example:
	contoso.onmicrosoft.com should be entered as "contoso"

    .EXAMPLE
    Add-OnMicrosoftSMTP -Tenant contoso
    This will add the required SMTP routing address for the tenant contoso.onmicrosoft.com
    Do not enter the full domain name, only the part before .onmicrosoft.com
#>
[cmdletbinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High"
    )]
param(
	[Parameter(Mandatory=$true)]
		[string]$Tenant = "Read-Host -Prompt `"Enter your tenant name - without the .onmicrosoft.com part:`""
	)

process {
        
    # Logging global settings and function
    $LogFileName = "Add-OnMicrosoftSMTP"
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
        
	function Add-OnMicrosoftSMTP ($tenant)
	{

	    $users = $null
	    $filter = $null
        $filter = ("*@" + $Tenant + ".mail.onmicrosoft.com")
        # Find mailbox users without email address policy enabled and a routing email address
	    $users = get-mailbox -Filter {EmailAddressPolicyEnabled -ne $true -And EmailAddresses -notlike $filter}

        writelog ("Will try to add routing SMTP addresses to " + $users.count + " mailboxes.")

	    foreach ($user in $users)
	    {
	        write-host -ForegroundColor White "`nMailbox" $user.DisplayName "Is not configured with a routing smtp address, trying to add one..."
	        # Check that the assumed routing smtp address value isn't already configured for a recipient
	        if (Get-Recipient ($user.PrimarySmtpAddress.ToString().Split("@")[0] + "@" + $Tenant + ".mail.onmicrosoft.com") -ErrorAction silentlycontinue) 
	        {
    	        write-host -ForegroundColor Yellow ($user.PrimarySmtpAddress.ToString().Split("@")[0] + "@" + $Tenant + ".mail.onmicrosoft.com") "Is conflicting with a different recipient..."

		        # Create a random suffix for the routing smtp address and add it to the mailbox
		        $Error.Clear()
                set-mailbox -ErrorAction:Stop -Identity $user.identity -EmailAddresses @{Add=($user.PrimarySmtpAddress.ToString().Split("@")[0] + (Get-Random -Minimum 11111 -Maximum 99999) + "@" + $Tenant + ".mail.onmicrosoft.com")}
		        if ($Error)
                {
                    writelog ("Failed to add the smtp routing address for " + $user.DistinguishedName)
		            writelog ("`tException Message: " + $Error[0].Exception.Message)
                }
                Else
                {
                    writelog ("Added " + ($user.PrimarySmtpAddress.ToString().Split("@")[0] + (Get-Random -Minimum 11111 -Maximum 99999) + "@" + $Tenant + ".mail.onmicrosoft.com") + " to " + $user.displayname)
                }
		        
            }
            Else
            {
				# Create a routing smtp address and add it to the mailbox    
				$Error.Clear()
                set-mailbox -ErrorAction:Stop -Identity $user.identity -EmailAddresses @{Add=($user.PrimarySmtpAddress.ToString().Split("@")[0] + "@" + $Tenant + ".mail.onmicrosoft.com")}
                if ($Error)
                {
                    writelog ("Failed to add the smtp routing address for " + $user.DistinguishedName)
		            writelog ("`tException Message: " + $Error[0].Exception.Message)
                }				
                Else
                {
                    writelog ("Added " + ($user.PrimarySmtpAddress.ToString().Split("@")[0] + "@" + $Tenant + ".mail.onmicrosoft.com") + " to " + $user.DisplayName)
				}
				
            }
	    }
        writelog ("Finished processing !")
    }
	

    ## Main Script Block

    $title = "Confirmation"
    $message = ("You entered " + $tenant + " as your Office 365 tenant name" + "`nThis will result in adding smtp routing addresses like:" + "`n" + ("John.Doe" + "@" + $Tenant + ".mail.onmicrosoft.com"))

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Continue with the script. The tenant name is correct."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "Stop and exit, the tenant name is incorrect"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result)
        {
            0 
			    { Write-Host -ForegroundColor Green "Proceeding with the script"
			    Write-Host -ForegroundColor Yellow "Log file will be created at" $home
			    Add-OnMicrosoftSMTP $tenant
			    }
            1
			    {Write-Host -ForegroundColor Red "Exiting script..."
			    Exit -1
			    }
        }
}
