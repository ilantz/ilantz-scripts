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

[XML]$dhcp1 = Get-Content C:\Users\ilantz\Desktop\dhcp1.xml
[XML]$dhcp2 = Get-Content C:\Users\ilantz\Desktop\dhcp2.xml

$scopesWithoutMatch = @()
$scopesWithLargerEndRange = @()

#merging DHCP2 scopes to DHCP1 scopes
foreach ($scope in $dhcp2.DHCPServer.IPv4.Scopes.Scope)
#foreach ($scope in ($dhcp2.DHCPServer.IPv4.Scopes.Scope | ? {$_.reservations -ne $null }))
#foreach ($scope in ($dhcp2.DHCPServer.IPv4.Scopes.Scope | ? {$_.scopeid -eq "10.128.100.0"}))
{
    #Trying to match scopes from DHCP2 to DHCP1
    $index = $dhcp1.DHCPServer.IPv4.Scopes.Scope.scopeid.IndexOf($scope.ScopeId)
    if ($index -ne "-1")
        {
        Write-Verbose ("Matched " + $scope.ScopeId + " to a scope in DHCP1")
        $targetScope = $dhcp1.DHCPServer.IPv4.Scopes.Scope[$index]
        #Overwriting EndRange value from DHCP2 scope
        #Checking that DHCP2 EndRange is indeed larger or equal to merge
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
                    $ReservationsNode = $dhcp1.CreateElement("Reservations")
                    $ReservationsNode.InnerXml = $scope.Reservations.InnerXml
                    $targetScope.AppendChild($ReservationsNode) | Out-Null
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
                        $ReservationEntry = $dhcp1.CreateElement("Reservation")
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
if ($scopesWithoutMatch)
    {
    Write-Warning ("Scopes without match were detected:")
    $scopesWithoutMatch
    }
if ($scopesWithLargerEndRange)
    {
    Write-Warning ("Scopes with a larger EndRange value in DHCP1 were detected:")
    $scopesWithLargerEndRange
    }