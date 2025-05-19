# WEB01-Setup.ps1
# Run this script inside web01 after Windows Server installation

# Configure Static IP
$iface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
New-NetIPAddress -InterfaceIndex $iface.ifIndex -IPAddress "172.16.0.12" -PrefixLength 24 -DefaultGateway "172.16.0.1"
Set-DnsClientServerAddress -InterfaceIndex $iface.ifIndex -ServerAddresses "172.16.0.10"

# Join the domain
$domain = "ad.local"
$username = "demouser"
$password = "demo!pass123"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$domain\$username", $securePassword)

# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Create a simple IIS welcome page
$html = @"
<!DOCTYPE html>
<html>
<head><title>web01 IIS</title></head>
<body><h1>web01 IIS is running</h1></body>
</html>
"@
Set-Content -Path "C:\inetpub\wwwroot\default.htm" -Value $html

Add-Computer -DomainName $domain -Credential $credential -Restart -Force
