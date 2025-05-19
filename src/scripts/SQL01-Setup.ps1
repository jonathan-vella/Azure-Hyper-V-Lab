# SQL01-Setup.ps1
# Run this script inside sql01 after Windows Server installation

# Configure Static IP
$iface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
New-NetIPAddress -InterfaceIndex $iface.ifIndex -IPAddress "172.16.0.11" -PrefixLength 24 -DefaultGateway "172.16.0.1"
Set-DnsClientServerAddress -InterfaceIndex $iface.ifIndex -ServerAddresses "172.16.0.10"

# Join the domain
$domain = "ad.local"
$username = "demouser"
$password = "demo!pass123"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$domain\$username", $securePassword)

Add-Computer -DomainName $domain -Credential $credential -Restart -Force
