# DC01-Setup.ps1
# Run this script inside dc01 after Windows Server installation

# Configure Static IP
$iface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
New-NetIPAddress -InterfaceIndex $iface.ifIndex -IPAddress "172.16.0.10" -PrefixLength 24 -DefaultGateway "172.16.0.1"
Set-DnsClientServerAddress -InterfaceIndex $iface.ifIndex -ServerAddresses "127.0.0.1"

# Install AD DS and DNS roles
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools

# Promote to domain controller for ad.local
$domainName = "ad.local"
$domainNetbios = "AD"
$securePassword = ConvertTo-SecureString "demo!pass123" -AsPlainText -Force

Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName $domainName `
    -DomainNetbiosName $domainNetbios `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $securePassword `
    -Force
# The server will reboot automatically after promotion.
