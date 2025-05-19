# Save-GuestScripts.ps1
# This script creates PowerShell scripts to configure each guest VM after OS installation
# These scripts are saved to the scripts directory for copying to guest VMs

$scriptsDir = "$PSScriptRoot"

# Domain Controller (DC01) configuration script
$dc01Script = @"
# DC01-Setup.ps1
# Run this script on dc01 after Windows Server installation

# Configure Static IP
$iface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
New-NetIPAddress -InterfaceIndex $iface.ifIndex -IPAddress "172.16.0.10" -PrefixLength 24 -DefaultGateway "172.16.0.1"
Set-DnsClientServerAddress -InterfaceIndex $iface.ifIndex -ServerAddresses "127.0.0.1"

# Install AD DS role and promote to domain controller
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools

# Create the new forest
Import-Module ADDSDeployment
$securePassword = ConvertTo-SecureString "demo!pass123" -AsPlainText -Force

Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "ad.local" `
    -DomainNetbiosName "AD" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $securePassword `
    -Force
# The server will automatically restart after promotion.
"@

# SQL Server (SQL01) configuration script
$sql01Script = @"
# SQL01-Setup.ps1
# Run this script on sql01 after Windows Server installation

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
"@

# Web Server (WEB01) configuration script
$web01Script = @"
# WEB01-Setup.ps1
# Run this script on web01 after Windows Server installation

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

# Install IIS role
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Create a simple welcome page
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Web01 - IIS Server</title>
</head>
<body>
    <h1>Web01 - IIS Server</h1>
    <p>This server is part of the Azure Hyper-V Lab environment.</p>
    <p>Server name: $env:COMPUTERNAME</p>
    <p>Domain: $env:USERDOMAIN</p>
    <p>Current time: $(Get-Date)</p>
</body>
</html>
"@
Set-Content -Path "C:\inetpub\wwwroot\default.htm" -Value $htmlContent

Add-Computer -DomainName $domain -Credential $credential -Restart -Force
"@

# Save the scripts to the scripts directory
$dc01Script | Out-File -FilePath "$scriptsDir\DC01-Setup.ps1" -Encoding UTF8
$sql01Script | Out-File -FilePath "$scriptsDir\SQL01-Setup.ps1" -Encoding UTF8
$web01Script | Out-File -FilePath "$scriptsDir\WEB01-Setup.ps1" -Encoding UTF8

# Create a readme file with instructions
$readme = @"
# Guest VM Setup Instructions

After installing Windows Server 2025 on each VM, follow these steps:

1. **Copy these scripts to each guest VM**
   - DC01-Setup.ps1 → dc01
   - SQL01-Setup.ps1 → sql01
   - WEB01-Setup.ps1 → web01

2. **Installation Order**:
   a. First run DC01-Setup.ps1 on dc01 and wait for it to reboot
   b. Then run SQL01-Setup.ps1 and WEB01-Setup.ps1 on their respective VMs

3. **Login Credentials for All VMs**:
   - Username: demouser
   - Password: demo!pass123
"@
$readme | Out-File -FilePath "$scriptsDir\GUEST-VM-INSTRUCTIONS.md" -Encoding UTF8
