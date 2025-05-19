# Setup-GuestVMs.ps1
# This script creates three Hyper-V guest VMs (dc01, sql01, web01) for nested virtualization in Azure
# It does NOT start the VMs. Run this script after logging into the Azure VM host.

$isoPath = "F:\VMS\ISO\WindowsServer2025Eval.iso"
$vmPath = "F:\VMS"
$diskPath = "F:\VMS\Disks"
$switchName = "Nat-Switch"

$guests = @(
    @{ Name = "dc01"; IP = "172.16.0.10"; CPU = 4; RAM = 4GB; Disk = 64GB },
    @{ Name = "sql01"; IP = "172.16.0.11"; CPU = 4; RAM = 8GB; Disk = 64GB },
    @{ Name = "web01"; IP = "172.16.0.12"; CPU = 4; RAM = 8GB; Disk = 64GB }
)

foreach ($g in $guests) {
    $vhdFile = Join-Path $diskPath "$($g.Name).vhdx"
    if (-not (Test-Path $vhdFile)) {
        Write-Host "Creating VHD for $($g.Name) ..." -ForegroundColor Cyan
        New-VHD -Path $vhdFile -SizeBytes $g.Disk -Dynamic
    }
    if (-not (Get-VM -Name $g.Name -ErrorAction SilentlyContinue)) {
        Write-Host "Creating VM: $($g.Name) ..." -ForegroundColor Cyan
        New-VM -Name $g.Name -MemoryStartupBytes $g.RAM -Generation 2 -Path $vmPath -SwitchName $switchName
        Add-VMHardDiskDrive -VMName $g.Name -Path $vhdFile
        Set-VMProcessor -VMName $g.Name -Count $g.CPU
        Set-VMMemory -VMName $g.Name -DynamicMemoryEnabled $false -StartupBytes $g.RAM
        Add-VMDvdDrive -VMName $g.Name -Path $isoPath
        $dvd = Get-VMDvdDrive -VMName $g.Name
        $bootOrder = @($dvd) + (Get-VMHardDiskDrive -VMName $g.Name)
        Set-VMFirmware -VMName $g.Name -BootOrder $bootOrder
        Enable-VMIntegrationService -VMName $g.Name -Name "Guest Service Interface"
        Write-Host "  VM $($g.Name) created and ISO mounted." -ForegroundColor Green
    } else {
        Write-Host "VM $($g.Name) already exists. Skipping creation." -ForegroundColor Yellow
    }
}

Write-Host "`nVMs are ready for OS installation. Do not start them yet." -ForegroundColor Green
Write-Host "After installing Windows Server in each VM, copy and run the corresponding setup script from C:\temp inside each VM." -ForegroundColor Cyan
