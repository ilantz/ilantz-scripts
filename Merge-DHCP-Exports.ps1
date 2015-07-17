<#
	.SYNOPSIS
    Merge-DHCP-Exports
   
    Ilan Lanz
    http://ilantz.com
	
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
    Version 1.0, 07/17/2015
    
    .DESCRIPTION
    WARNING: This script was written for a specific situation.
    Merging two DHCP servers serving the SAME scopes with different StartRange and EndRange values, for example:
    
    DHCP1 - Target:
    --------------------------------
    ScopeId         : 192.168.0.0
    Name            : Scope1
    SubnetMask      : 255.255.248.0
    StartRange      : 192.168.0.0
    EndRange        : 192.168.3.255

    DHCP2 - Source:
    --------------------------------
    ScopeId         : 192.168.0.0
    Name            : Scope1
    SubnetMask      : 255.255.248.0
    StartRange      : 192.168.4.0
    EndRange        : 192.168.7.255
        
    The script will allow you to merge two DHCP XML export files using the Export-DhcpServer cmdlet.
    It will match the scopes from the "source" DHCP XML export and will match them to the "target" scopes.
    EndRange values of each scope will be overwritten by the values from the "source".
    Reservations will be evaluated: each reserved IPAddress will be looked up at the "target" scope and will be added if determined to be missing.
    The TargetXML file will saved under a new name and will allow you to import it back to the Target DHCP server.
    
    This will eventually allow you to enable the Failover DHCP in Server 2012 & 2012R2 and take full advantage of the feature.
               
    Revision History
    --------------------------------------------------------------------------------
    1.0     Initial release
	
    .PARAMETER TargetXML
    The name of the XML export file representing the Target DHCP.
	Following the example in the description, this will be the XML export from DHCP1.
	
    .PARAMETER SourceXML
    The name of the XML export file representing the Source DHCP.
	Following the example in the description, this will be the XML export from DHCP2.
	
    .EXAMPLE
    Merge-DHCP-Exports -TargetXML C:\DHCP-Exports\DHCP1.XML -SourceXML C:\DHCP-Exports\DHCP2.XML -Verbose

    This Example will merge the DHCP2 export to the DHCP1 export file and show all verbose messages (highly recommended..).
        
#>
[cmdletbinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High"
    )]

param(
    [Parameter(Mandatory=$true,HelpMessage="Enter the Target DHCP XML export filepath.")]
    [ValidateScript({Test-Path $_})]
    [String]$TargetXML = $args[0],

    [Parameter(Mandatory=$true,HelpMessage="Enter the Source DHCP XML export filepath.")]
    [ValidateScript({Test-Path $_})]
    [String]$SourceXML = $args[1]
    )

process {


#Convert an IP to binary function from:
#http://www.indented.co.uk/2010/01/23/powershell-subnet-math/
function ConvertTo-BinaryIP {
  <#
    .Synopsis
      Converts a Decimal IP address into a binary format.
    .Description
      ConvertTo-BinaryIP uses System.Convert to switch between decimal and binary format. The output from this function is dotted binary.
    .Parameter IPAddress
      An IP Address to convert.
  #>
 
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [Net.IPAddress]$IPAddress
  )
 
  process {  
    return [String]::Join('.', $( $IPAddress.GetAddressBytes() |
      ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') } ))
  }
}
$TargetXMLPath = $TargetXML
[XML]$TargetXML = Get-Content $TargetXML
[XML]$SourceXML = Get-Content $SourceXML

$scopesWithoutMatch = @()
$scopesWithLargerEndRange = @()

#merging DHCP2 scopes to DHCP1 scopes
foreach ($scope in $SourceXML.DHCPServer.IPv4.Scopes.Scope)
    {
    #Trying to match scopes from DHCP2 to DHCP1
    $index = $TargetXML.DHCPServer.IPv4.Scopes.Scope.scopeid.IndexOf($scope.ScopeId)
    if ($index -ne "-1")
        {
        Write-Verbose ("Matched " + $scope.ScopeId + " to a scope in DHCP1")
        $targetScope = $TargetXML.DHCPServer.IPv4.Scopes.Scope[$index]
        #Checking that DHCP2 EndRange is indeed larger or equal to overwrite value on DHCP1 scope
        if ((ConvertTo-BinaryIP $targetScope.EndRange) -le (ConvertTo-BinaryIP $scope.EndRange))
            {
            Write-Verbose ("`tUpdating EndRange from " + `
            $targetScope.EndRange + " to " + $scope.EndRange)
            $targetScope.EndRange = $scope.EndRange
            }
            ELSE
            {
            Write-Verbose ("Destination EndRange value on scope " `
            + $scope.ScopeId + " is grater than EndRange at source")
            $LargerscopeObj = New-Object System.Object
            $LargerscopeObj | Add-Member -type NoteProperty -name ScopeID -value $scope.ScopeId
            $LargerscopeObj | Add-Member -type NoteProperty -name EndRange-DHCP1 -value $targetScope.EndRange
            $LargerscopeObj | Add-Member -type NoteProperty -name EndRange-DHCP2 -value $scope.EndRange
            $scopesWithLargerEndRange += $LargerscopeObj
            }

        #Merging reservations
        if ($scope.reservations)
            {
            foreach ($reservation in $scope.reservations.reservation)
                {
                if (! $targetScope.Reservations)
                    {
                    Write-Verbose ("`t`tAdding reservation for IP " + $reservation.IPAddress)
                    $ReservationsNode = $null
                    $ReservationsNode = $TargetXML.CreateElement("Reservations")
                    $ReservationsNode.InnerXml = $scope.Reservations.InnerXml
                    #Insert new Node at proper location
                    $targetScope.InsertBefore($ReservationsNode,$targetScope.LastChild) | Out-Null
                    }
                    elseif ($targetScope.Reservations.InnerXml.Contains($reservation.IPAddress))
                        {
                        Write-Verbose ("`t`tSkipping reservation for IP " + $reservation.IPAddress + `
                        " because it already exists in target scope.")
                        }
                    else
                    {
                        Write-Verbose ("`t`tAdding reservation for IP " + $reservation.IPAddress)
                        $ReservationEntry = $null
                        $ReservationEntry = $TargetXML.CreateElement("Reservation")
                        $ReservationEntry.InnerXml = $reservation.InnerXml
                        $targetScope.Reservations.AppendChild($ReservationEntry) | Out-Null
                     }
                    
                }
            }
        }
        ELSE
        {
        Write-Verbose ("No match for " + $scope.ScopeId + " in DHCP1")
        $scopesWithoutMatch += $scope.ScopeId
        }
    }

#Write warning if any Scopes from DHCP2 were not matched to scopes in DHCP1
if ($scopesWithoutMatch)
    {
    Write-Output "`n"
    Write-Warning ("Scopes without match were detected:")
    $scopesWithoutMatch
    }
#Write warning if any scope from DHCP2 had a larger EndRange value than a scope in DHCP1
if ($scopesWithLargerEndRange)
    {
    Write-Output "`n"
    Write-Warning ("Scopes with a larger EndRange value in DHCP1 were detected:")
    $scopesWithLargerEndRange
    }

#saving merged XML to a new file
$MergedXML = (Get-Item $TargetXMLPath).Directory.FullName + "\" + (Get-Item $TargetXMLPath).BaseName + "-Merged.xml"
Write-Output "`n"
Write-Output ("Merged XML file will be saved to: " + $MergedXML)
$TargetXML.Save($MergedXML)
}