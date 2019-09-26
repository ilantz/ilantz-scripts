## Installing a Microsoft Teams bot application for all users
##
## Prerequisites 
## 
## 1. Create a new application registeration in Azure AD
## 		a. name it what ever you like
## 		b. redirect URI should be https://localhost
## 		c. note the Application (client) ID value and enter it in the $clientid variable
## 		d. create a secret for the application and enter it in the $clientSecret variable
## 		e. assign and provide consent to the following API Permissions for the Microsoft Graph API
##			# Note these are Application permissions:
##			Chat.Read.All
##			Directory.Read.All
##			Directory.ReadWrite.All
##			User.Read.All
##			User.ReadWrite.All
## 2. Locate the teams application id, easiest way would be to open the web app for teams, navigate to the application and copy the value .../apps/<ID HERE>/sections...
## 	  For example : https://teams.microsoft.com/_#/apps/243254ad-482a-4cdd-ba4f-xxxx0541c6/sections/com.contoso.Announcement.history
##    243254ad-482a-4cdd-ba4f-xxxx0541c6 is the value in this example
##
##
$clientid = "<application client ID>"
$tenantName = "<your tenant name>.onmicrosoft.com"
$clientSecret = "<client secret>"
$teamsApplicationid = "<your teams bot application id>"
##
##
############################################################

$resource = "https://graph.microsoft.com/"
 
$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
} 
 

$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody

## List all users
$apiUrl = 'https://graph.microsoft.com/beta/users'
$users = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $apiUrl -Method Get

foreach ($user in $users.value) {

$userid = $user.id

    ## Check if the application is already instaled, and if not install it for the user

    $apiUrl = "https://graph.microsoft.com/beta/users/$userid/teamwork/installedApps?`$expand=teamsAppDefinition&`$filter=teamsAppDefinition/teamsAppId eq '$teamsApplicationid'"
    $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $apiUrl -Method Get
    
    if (!$data.value) {
    
	    $apiUrl = "https://graph.microsoft.com/beta/users/$userid/teamwork/installedApps"
	    $body = '{"teamsApp@odata.bind":"https://graph.microsoft.com/beta/appCatalogs/teamsApps/'+$teamsApplicationid+'"}'
	    Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $apiUrl -Method POST -ContentType 'Application/Json' -Body $body
	    ## Workaround to create a conversation ID

	    $apiUrl = "https://graph.microsoft.com/beta/users/$userid/chats?`$filter=installedApps/any(x:x/teamsApp/id eq '$teamsApplicationid')"
	    Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $apiUrl -Method Get
    }
}
