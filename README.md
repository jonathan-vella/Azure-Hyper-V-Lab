# 🚀 Azure Hyper-V Lab

[![Azure Deploy](https://img.shields.io/badge/Azure-Deploy-blue?logo=microsoft-azure)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjonathan-vella%2FAzure-Hyper-V-Lab%2Fmain%2Fsrc%2Fbicep%2Fazuredeploy.json)
[![License](https://img.shields.io/github/license/jonathan-vella/Azure-Hyper-V-Lab)](https://github.com/jonathan-vella/Azure-Hyper-V-Lab/blob/main/LICENSE)
[![Bicep](https://img.shields.io/badge/Infrastructure%20as%20Code-Bicep-blue?logo=azure-pipelines)](https://github.com/jonathan-vella/Azure-Hyper-V-Lab/tree/main/src/bicep)
[![PowerShell](https://img.shields.io/badge/Language-PowerShell-blue?logo=powershell)](https://github.com/jonathan-vella/Azure-Hyper-V-Lab/tree/main/src/scripts)
[![Hyper-V](https://img.shields.io/badge/Platform-Hyper--V-blue?logo=microsoft)](https://github.com/jonathan-vella/Azure-Hyper-V-Lab/tree/main)
[![Docs](https://img.shields.io/badge/docs-available-brightgreen)](https://github.com/jonathan-vella/Azure-Hyper-V-Lab#documentation)
[![Contributions](https://img.shields.io/badge/contributions-welcome-orange)](https://github.com/jonathan-vella/Azure-Hyper-V-Lab/blob/main/CONTRIBUTING.md)


Welcome to the **Azure Hyper-V Lab**! Easily deploy a Windows Server 2025 Datacenter VM with Hyper-V in Azure, complete with nested virtualization, pre-installed tools, and a modular, production-ready Bicep template.

---

## 🗺️ Quick Navigation
- [🚀 Azure Hyper-V Lab](#-azure-hyper-v-lab)
  - [🗺️ Quick Navigation](#️-quick-navigation)
  - [🚀 What's New](#-whats-new)
  - [🌟 What's Included](#-whats-included)
    - [Infrastructure](#infrastructure)
    - [Server Roles](#server-roles)
    - [Pre-Installed Software](#pre-installed-software)
  - [☕ Brew Bliss Coffee Shop Web Application](#-brew-bliss-coffee-shop-web-application)
  - [🚦 Get Started](#-get-started)
  - [🧩 Modular Bicep Code Structure](#-modular-bicep-code-structure)
  - [🚀 Deployment Options](#-deployment-options)
    - [Azure Portal](#azure-portal)
    - [Azure CLI](#azure-cli)
    - [PowerShell](#powershell)
    - [Bash](#bash)
  - [📝 General Notes](#-general-notes)
  - [📚 Learn More About Hyper-V](#-learn-more-about-hyper-v)
  - [🛠️ Troubleshooting](#️-troubleshooting)
    - [Common Issues](#common-issues)

---

## 🚀 What's New
- **Modular Bicep code structure** for best practices
- **Separation of concerns** for maintainability
- **Reusable modules** for easy extension
- **Multiple deployment options** (PowerShell, Azure CLI, Portal)

See the [Modular Template Guide](./MODULAR-TEMPLATE-GUIDE.md) for details.

---

## 🌟 What's Included

### Infrastructure
- **Virtual Network (VNet)** with subnet
- **Static Public IP** (Standard SKU)
- **Network Security Group (NSG)** for RDP
- **Azure VM** with Nested Virtualization ([Learn more](https://www.markou.me))
- **Premium SSD Disks**: 127GB (OS), 512GB (VMs)

### Server Roles
- **Hyper-V**
- **DHCP Server**
- **RSAT Tools**
- **Containers**

### Pre-Installed Software
- Azure Az PowerShell Module
- Azure CLI
- Azure Storage Explorer
- AzCopy Utility
- PowerShell Core
- Windows Admin Center
- 7-Zip
- Chocolatey
- Windows Server 2025 Evaluation

---

## ☕ Brew Bliss Coffee Shop Web Application

A sample web app is included in `src/eshop`:
- `CoffeeShopWebDeploy.zip`: Web app package
- `Deploy-CoffeeShop.ps1`: PowerShell deployment script

After deploying the Azure VM, the deployment script is auto-copied to `C:\temp` for easy use inside your lab.

---

## 🚦 Get Started

See [DEPLOY.md](./DEPLOY.md) for a step-by-step, end-to-end deployment guide with screenshots.

---

## 🧩 Modular Bicep Code Structure

- **main.bicep**: Orchestrates all modules
- **modules/network.bicep**: VNet, Subnet, NSG, Public IP, NIC
- **modules/vm.bicep**: VM configuration
- **modules/vm-extensions.bicep**: DSC & custom script extensions

**Helpful Resources:**
- [QUICKSTART.md](./QUICKSTART.md): Quick start
- [MODULAR-TEMPLATE-GUIDE.md](./MODULAR-TEMPLATE-GUIDE.md): Modular structure
- `Test-Deployment.ps1`: Test deployment
- `Deploy-HyperVLab.ps1`: PowerShell deployment
- `deploy-hyperv-lab.sh`: Bash deployment
- `Update-GitHubUrls.ps1`: Update GitHub URLs
- `Check-ParameterFiles.ps1`: Validate parameter files
- `Validate-Templates.ps1`: Template validation

---

## 🚀 Deployment Options

### Azure Portal
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjonathan-vella%2FAzure-Hyper-V-Lab%2Fmain%2Fsrc%2Fbicep%2Fmain.json)

### Azure CLI
```bash
az group create --name HyperVLab --location swedencentral
az deployment group create \
  --resource-group HyperVLab \
  --template-file src/bicep/main.bicep \
  --parameters computerName=hypervhost AdminUsername=demouser AdminPassword='demo!pass123'
```

### PowerShell
```powershell
# Recommended
.\src\scripts\Deploy-HyperVLab.ps1 -ResourceGroupName "MyHyperVLab" -Location "swedencentral" -AdminPassword (ConvertTo-SecureString -String 'demo!pass123' -AsPlainText -Force)

# Manual
New-AzResourceGroup -Name HyperVLab -Location swedencentral
New-AzResourceGroupDeployment -ResourceGroupName HyperVLab -TemplateFile src\bicep\main.bicep -computerName hypervhost -AdminUsername yourUsername -AdminPassword (ConvertTo-SecureString -String 'demo!pass123' -AsPlainText -Force)
```

### Bash
```bash
chmod +x ./src/scripts/deploy-hyperv-lab.sh
./src/scripts/deploy-hyperv-lab.sh --resource-group MyHyperVLab --location swedencentral --password 'demo!pass123'
```

---

## 📝 General Notes
- **No public IP**: Access via Azure Bastion for security
- **Azure Bastion**: Choose Basic or Standard SKU
- **VM sizes**: Pre-configured to avoid errors
- **Spot Instances**: Eviction policy set to `deallocate`
- **Shortcuts**: Microsoft Evaluation Center, Hyper-V Manager, and more on desktop
- **Default Paths**:
  - VM configs: `F:\VMS`
  - VM disks: `F:\VMS\Disks`
- **Enhanced Session Mode** enabled
- **DHCP Scope** and **Internal Hyper-V Switch** with NAT
- **Data disk**: ReFS, 64KB unit size
- **Templates**: Both JSON and Bicep
- **Config Files**:
  - [DSC Config](dsc/DSCInstallWindowsFeatures.ps1)
  - [Host Config](src/scripts/HostConfig.ps1)

---

## 📚 Learn More About Hyper-V
- [Windows Server Hyper-V and Virtualization Learning Path](https://docs.microsoft.com/en-us/learn/paths/windows-server-hyper-v-virtualization/)
- [Markou.me Hyper-V Blog](https://www.markou.me/category/hyper-v/)
- [Virtualization Blog](https://techcommunity.microsoft.com/t5/virtualization/bg-p/Virtualization)
- [MSLab GitHub Project](https://github.com/microsoft/MSLab)

---

## 🛠️ Troubleshooting

### Common Issues

#### InvalidResourceLocation Error
```json
{
  "status": "Failed",
  "error": {
    "code": "InvalidResourceLocation",
    "message": "The specified location '[resourceGroup().location]' is invalid."
  }
}
```
**Solution:** In your parameter files, use a real Azure region name (e.g., `swedencentral`), not an ARM expression.

#### Script Errors
- Ensure Azure PowerShell or CLI is installed
- Check Azure login and permissions
- Verify your subscription supports the selected VM size

---

**Ready to get started? See [DEPLOY.md](./DEPLOY.md) for the full deployment guide!**
