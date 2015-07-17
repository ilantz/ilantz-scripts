<#
.SYNOPSIS
    The script sets the UsageLocation value for Office 365 users based on the Country attribute value.
.DESCRIPTION
    Before using the script, install, load and connect to the Windows Azure AD Module - http://aka.ms/aadposh
	
	The script will list all users within Office 365,
	It will filter out all licensed users (they should be already configured with the UsageLocation),
	Iterate thru each user and tries to match the country value with a pre-defined hashtable of 249 country codes,
	And configure the two letter code for the UsageLocation value.
	
	Keep in mind that the script will not handle any spelling errors, so be sure to maintain the country value BEFORE you run this script.
	The script will try to find an exact match of the country value, although - case Insensitive.
	
.NOTES
    File Name: Set-MSOL-UsageLocation.ps1
	Version: 0.1
	Last Update: 10/Apr/2014
    Author   : Ilan Lanz, http://ilantz.com
    The script are provided “AS IS” with no guarantees, no warranties, USE ON YOUR OWN RISK.    
#>

# 249 Official country codes from - https://www.iso.org/obp/ui
# Please also see http://office.microsoft.com/en-001/business/microsoft-office-license-restrictions-FX103037529.aspx for more official Office 365 Licensing restrictions
$CountryHashTable = @{ `
"Afghanistan" = "AF"; `
"Åland Islands" = "AX"; `
"Albania" = "AL"; `
"Algeria" = "DZ"; `
"American Samoa" = "AS"; `
"Andorra" = "AD"; `
"Angola" = "AO"; `
"Anguilla" = "AI"; `
"Antarctica" = "AQ"; `
"Antigua and Barbuda" = "AG"; `
"Argentina" = "AR"; `
"Armenia" = "AM"; `
"Aruba" = "AW"; `
"Australia" = "AU"; `
"Austria" = "AT"; `
"Azerbaijan" = "AZ"; `
"Bahamas" = "BS"; `
"Bahrain" = "BH"; `
"Bangladesh" = "BD"; `
"Barbados" = "BB"; `
"Belarus" = "BY"; `
"Belgium" = "BE"; `
"Belize" = "BZ"; `
"Benin" = "BJ"; `
"Bermuda" = "BM"; `
"Bhutan" = "BT"; `
"Bolivia" = "BO"; `
"Bonaire, Sint Eustatius and Saba" = "BQ"; `
"Bosnia and Herzegovina" = "BA"; `
"Botswana" = "BW"; `
"Bouvet Island" = "BV"; `
"Brazil" = "BR"; `
"British Indian Ocean Territory" = "IO"; `
"Brunei Darussalam" = "BN"; `
"Bulgaria" = "BG"; `
"Burkina Faso" = "BF"; `
"Burundi" = "BI"; `
"Cabo Verde" = "CV"; `
"Cambodia" = "KH"; `
"Cameroon" = "CM"; `
"Canada" = "CA"; `
"Cayman Islands" = "KY"; `
"Central African Republic" = "CF"; `
"Chad" = "TD"; `
"Chile" = "CL"; `
"China" = "CN"; `
"Christmas Island" = "CX"; `
"Cocos (Keeling) Islands" = "CC"; `
"Colombia" = "CO"; `
"Comoros" = "KM"; `
"Congo" = "CG"; `
"Congo (DRC)" = "CD"; `
"Cook Islands" = "CK"; `
"Costa Rica" = "CR"; `
"Côte d'Ivoire" = "CI"; `
"Croatia" = "HR"; `
"Cuba" = "CU"; `
"Curaçao" = "CW"; `
"Cyprus" = "CY"; `
"Czech Republic" = "CZ"; `
"Denmark" = "DK"; `
"Djibouti" = "DJ"; `
"Dominica" = "DM"; `
"Dominican Republic" = "DO"; `
"Ecuador" = "EC"; `
"Egypt" = "EG"; `
"El Salvador" = "SV"; `
"Equatorial Guinea" = "GQ"; `
"Eritrea" = "ER"; `
"Estonia" = "EE"; `
"Ethiopia" = "ET"; `
"Falkland Islands (Malvinas)" = "FK"; `
"Faroe Islands" = "FO"; `
"Fiji" = "FJ"; `
"Finland" = "FI"; `
"France" = "FR"; `
"French Guiana" = "GF"; `
"French Polynesia" = "PF"; `
"French Southern Territories" = "TF"; `
"Gabon" = "GA"; `
"Gambia" = "GM"; `
"Georgia" = "GE"; `
"Germany" = "DE"; `
"Ghana" = "GH"; `
"Gibraltar" = "GI"; `
"Greece" = "GR"; `
"Greenland" = "GL"; `
"Grenada" = "GD"; `
"Guadeloupe" = "GP"; `
"Guam" = "GU"; `
"Guatemala" = "GT"; `
"Guernsey" = "GG"; `
"Guinea" = "GN"; `
"Guinea-Bissau" = "GW"; `
"Guyana" = "GY"; `
"Haiti" = "HT"; `
"Heard Island and McDonald Islands" = "HM"; `
"Holy See (Vatican City State)" = "VA"; `
"Honduras" = "HN"; `
"Hong Kong" = "HK"; `
"Hungary" = "HU"; `
"Iceland" = "IS"; `
"India" = "IN"; `
"Indonesia" = "ID"; `
### Not currently available as a usage location in Office 365 ### "Iran (the Islamic Republic of)" = "IR"; `
"Iraq" = "IQ"; `
"Ireland" = "IE"; `
"Isle of Man" = "IM"; `
"Israel" = "IL"; `
"Italy" = "IT"; `
"Jamaica" = "JM"; `
"Japan" = "JP"; `
"Jersey" = "JE"; `
"Jordan" = "JO"; `
"Kazakhstan" = "KZ"; `
"Kenya" = "KE"; `
"Kiribati" = "KI"; `
### Not currently available as a usage location in Office 365 ### "Korea (the Democratic People's Republic of)" = "KP"; `
"Korea, Republic of" = "KR"; `
"Kuwait" = "KW"; `
"Kyrgyzstan" = "KG"; `
"Lao People's Democratic Republic" = "LA"; `
"Latvia" = "LV"; `
"Lebanon" = "LB"; `
"Lesotho" = "LS"; `
"Liberia" = "LR"; `
"Libya" = "LY"; `
"Liechtenstein" = "LI"; `
"Lithuania" = "LT"; `
"Luxembourg" = "LU"; `
"Macao" = "MO"; `
"Macedonia, the former Yugoslav Republic of" = "MK"; `
"Madagascar" = "MG"; `
"Malawi" = "MW"; `
"Malaysia" = "MY"; `
"Maldives" = "MV"; `
"Mali" = "ML"; `
"Malta" = "MT"; `
"Marshall Islands" = "MH"; `
"Martinique" = "MQ"; `
"Mauritania" = "MR"; `
"Mauritius" = "MU"; `
"Mayotte" = "YT"; `
"Mexico" = "MX"; `
"Micronesia" = "FM"; `
"Moldova" = "MD"; `
"Monaco" = "MC"; `
"Mongolia" = "MN"; `
"Montenegro" = "ME"; `
"Montserrat" = "MS"; `
"Morocco" = "MA"; `
"Mozambique" = "MZ"; `
### Not currently available as a usage location in Office 365 ### "Myanmar" = "MM"; `
"Namibia" = "NA"; `
"Nauru" = "NR"; `
"Nepal" = "NP"; `
"Netherlands" = "NL"; `
"New Caledonia" = "NC"; `
"New Zealand" = "NZ"; `
"Nicaragua" = "NI"; `
"Niger" = "NE"; `
"Nigeria" = "NG"; `
"Niue" = "NU"; `
"Norfolk Island" = "NF"; `
"Northern Mariana Islands" = "MP"; `
"Norway" = "NO"; `
"Oman" = "OM"; `
"Pakistan" = "PK"; `
"Palau" = "PW"; `
"Palestine, State of" = "PS"; `
"Panama" = "PA"; `
"Papua New Guinea" = "PG"; `
"Paraguay" = "PY"; `
"Peru" = "PE"; `
"Philippines" = "PH"; `
"Pitcairn" = "PN"; `
"Poland" = "PL"; `
"Portugal" = "PT"; `
"Puerto Rico" = "PR"; `
"Qatar" = "QA"; `
"Réunion" = "RE"; `
"Romania" = "RO"; `
"Russian Federation" = "RU"; `
"Rwanda" = "RW"; `
"Saint Barthélemy" = "BL"; `
"Saint Helena, Ascension and Tristan da Cunha" = "SH"; `
"Saint Kitts and Nevis" = "KN"; `
"Saint Lucia" = "LC"; `
"Saint Martin" = "MF"; `
"Saint Pierre and Miquelon" = "PM"; `
"Saint Vincent and the Grenadines" = "VC"; `
"Samoa" = "WS"; `
"San Marino" = "SM"; `
"Sao Tome and Principe" = "ST"; `
"Saudi Arabia" = "SA"; `
"Senegal" = "SN"; `
"Serbia" = "RS"; `
"Seychelles" = "SC"; `
"Sierra Leone" = "SL"; `
"Singapore" = "SG"; `
"Sint Maarten" = "SX"; `
"Slovakia" = "SK"; `
"Slovenia" = "SI"; `
"Solomon Islands" = "SB"; `
"Somalia" = "SO"; `
"South Africa" = "ZA"; `
"South Georgia and the South Sandwich Islands" = "GS"; `
"South Sudan " = "SS"; `
"Spain" = "ES"; `
"Sri Lanka" = "LK"; `
"Sudan" = "SD"; `
"Suriname" = "SR"; `
"Svalbard and Jan Mayen" = "SJ"; `
"Swaziland" = "SZ"; `
"Sweden" = "SE"; `
"Switzerland" = "CH"; `
"Syrian Arab Republic" = "SY"; `
"Taiwan" = "TW"; `
"Tajikistan" = "TJ"; `
"Tanzania" = "TZ"; `
"Thailand" = "TH"; `
"Timor-Leste" = "TL"; `
"Togo" = "TG"; `
"Tokelau" = "TK"; `
"Tonga" = "TO"; `
"Trinidad and Tobago" = "TT"; `
"Tunisia" = "TN"; `
"Turkey" = "TR"; `
"Turkmenistan" = "TM"; `
"Turks and Caicos Islands" = "TC"; `
"Tuvalu" = "TV"; `
"Uganda" = "UG"; `
"Ukraine" = "UA"; `
"United Arab Emirates" = "AE"; `
"United Kingdom" = "GB"; `
"United States" = "US"; `
"United States Minor Outlying Islands" = "UM"; `
"Uruguay" = "UY"; `
"Uzbekistan" = "UZ"; `
"Vanuatu" = "VU"; `
"Venezuela, Bolivarian Republic of" = "VE"; `
"Viet Nam" = "VN"; `
"Virgin Islands, British" = "VG"; `
"Virgin Islands, U.S." = "VI"; `
"Wallis and Futuna" = "WF"; `
"Western Sahara*" = "EH"; `
"Yemen" = "YE"; `
"Zambia" = "ZM"; `
"Zimbabwe" = "ZW"; `
};

# grabbing all users from Office 365
$users = get-msoluser -all
# filtering out users with UsageLocation already set and users with empty country value
$users = $users | ? {$_.UsageLocation -eq $null -AND $_.Country -ne $null}

foreach ($user in $users)
{
# trying to match the country value with a two letter code country, skiping the user if no match was found
		if ($CountryHashTable.Item($user.Country))
		{ 
# setting the value of UsageLocation if a two letter country code was matched
		Write-Host "Will set" $CountryHashTable.Item($user.Country) "as the usage location for" $user.UserPrincipalName
		Set-MsolUser -UserPrincipalName $user.UserPrincipalName -UsageLocation($CountryHashTable.Item($user.Country))	
		}
		ELSE 
		{Write-Host "No conntry code was found for" $user.UserPrincipalName "with country value of" $user.Country }
}
