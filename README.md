# 🚀 Azure Hyper-V Lab

Welcome to the **Azure Hyper-V Lab**! This project provides an Azure IaaS VM Deployment Template for **Windows Server 2025 Datacenter Edition** with the **Hyper-V Role** enabled. Whether you're experimenting, learning, developing proofs of concept, or setting up a staging environment, this template simplifies the process and empowers you to leverage Hyper-V in Azure.

---

## 🚀 What's New!

This project has been modernized with a **modular Bicep code structure** that follows Azure best practices. The new structure provides:

- **Improved maintainability** through separation of concerns
- **Better code organization** with dedicated modules for each resource type
- **Increased reusability** for components in other projects
- **Enhanced deployment options** with both PowerShell and Azure CLI scripts

See the [Modular Template Guide](./MODULAR-TEMPLATE-GUIDE.md) for details on the new structure.

## 🌟 What's Included?

### Infrastructure:
- **Virtual Network (VNet)** with a single Subnet
- **Static Public IP** (Standard SKU)
- **Network Security Group (NSG)** configured for Remote Desktop access
- **Virtual Machine** with Nested Virtualization capabilities ([Learn more](https://www.markou.me))
- **Premium SSD Disks**:
  - 127GB for the Operating System
  - 512GB for storing Virtual Machines

### Server Roles:
- **Hyper-V**
- **DHCP Server**
- **RSAT Tools**
- **Containers**

### Pre-Installed Software:
- **Azure Az PowerShell Module**
- **Azure CLI**
- **Azure Storage Explorer**
- **AzCopy Utility**
- **PowerShell Core**
- **Windows Admin Center**
- **7-Zip**
- **Chocolatey Package Manager**
- **Evaluation copy of Windows Server 2025**

---

## 🚀 Get Started

See [DEPLOY.md](./DEPLOY.md) for step-by-step deployment instructions and screenshots.

---

## 🧰 Modular Bicep Code Structure

The deployment uses a modular Bicep code structure for better maintainability and scalability:

### Modules Organization:
- **main.bicep**: Main deployment template that orchestrates all modules
- **modules/network.bicep**: Network resources (VNet, Subnet, NSG, Public IP, NIC)
- **modules/vm.bicep**: Virtual machine configuration
- **modules/vm-extensions.bicep**: VM extensions for DSC and custom script

### Helpful Resources:
- **QUICKSTART.md**: Get started quickly with step-by-step instructions
- **MODULAR-TEMPLATE-GUIDE.md**: Detailed documentation on the modular structure
- **Test-Deployment.ps1**: Test the deployment without creating resources
- **Deploy-HyperVLab.ps1**: PowerShell deployment script
- **deploy-hyperv-lab.sh**: Bash deployment script
- **Update-GitHubUrls.ps1**: Script to update all GitHub URLs after forking
- **Check-ParameterFiles.ps1**: Validate parameter files for common issues
- **Validate-Templates.ps1**: Full template validation

### Deployment Options:

#### Azure Portal Deployment:
Click the button below to deploy the template directly in the Azure Portal:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjonathan-vella%2FAzure-Hyper-V-Lab%2Fmain%2Fsrc%2Fbicep%2Fmain.json)

#### Azure CLI Deployment:
```bash
# Create a resource group
az group create --name HyperVLab --location swedencentral

# Deploy the Bicep template
az deployment group create \
  --resource-group HyperVLab \
  --template-file src/bicep/main.bicep \
  --parameters computerName=hypervhost AdminUsername=demouser AdminPassword='demo!pass123'
```

#### PowerShell Deployment:
```powershell
# Option 1: Use the deployment script (recommended)
.\src\scripts\Deploy-HyperVLab.ps1 -ResourceGroupName "MyHyperVLab" -Location "swedencentral" -AdminPassword (ConvertTo-SecureString -String 'demo!pass123' -AsPlainText -Force)

# Option 2: Manual deployment
New-AzResourceGroup -Name HyperVLab -Location swedencentral

New-AzResourceGroupDeployment `
  -ResourceGroupName HyperVLab `
  -TemplateFile src\bicep\main.bicep `
  -computerName hypervhost `
  -AdminUsername yourUsername `
  -AdminPassword (ConvertTo-SecureString -String 'demo!pass123' -AsPlainText -Force)
```

### Bash/Azure CLI Deployment:
```bash
# Option 1: Use the deployment script (recommended)
chmod +x ./src/scripts/deploy-hyperv-lab.sh
./src/scripts/deploy-hyperv-lab.sh --resource-group MyHyperVLab --location swedencentral --password 'demo!pass123'

# Option 2: Manual deployment
az group create --name HyperVLab --location swedencentral

az deployment group create \
  --resource-group HyperVLab \
  --template-file main.bicep \
  --parameters computerName=hypervhost AdminUsername=demouser AdminPassword='demo!pass123'
```

## 📝 General Notes

> **Important**: Before sharing or using this repository, replace all instances of `jonathan-vella` with your actual GitHub username in the URLs and code.

- **Enhanced Security**: The VM has no public IP address and is accessed through Azure Bastion for improved security.
- **Azure Bastion**: Choose between Basic or Standard SKU based on your needs. Basic SKU provides essential connectivity while Standard offers additional features.
- A wide range of VM sizes is pre-configured in the template to avoid deployment errors.
- The VM uses **Azure Spot Instances** with an eviction policy set to `deallocate`.
- Use the **Microsoft Evaluation Center** desktop shortcut to evaluate Microsoft software and operating systems.
- Learn how to deploy VMs using Azure Marketplace Images on my [blog](https://www.markou.me/2022/03/use-azure-marketplace-images-to-deploy-virtual-machines-on-azure-stack-hci/).
- **Default Paths**:
  - VM configuration files: `F:\VMS`
  - VM disks: `F:\VMS\Disks`
- **Enhanced Session Mode** is enabled.
- A **DHCP Scope** is configured to provide network addressing for VMs.
- An **Internal Hyper-V Switch** with NAT enabled is included.
- The data disk (`Volume F`) is formatted with **ReFS** and a unit size of 64KB.
- Both **JSON** and **Bicep Templates** are available in this repository.
- **Configuration Files**:
  - [DSC Configuration File](dsc/DSCInstallWindowsFeatures.ps1)
  - [Host Configuration File](/HostConfig.ps1)

---

## 📚 Learn More About Hyper-V

- [Windows Server Hyper-V and Virtualization Learning Path](https://docs.microsoft.com/en-us/learn/paths/windows-server-hyper-v-virtualization/) on Microsoft Learn
- [Markou.me Hyper-V Blog](https://www.markou.me/category/hyper-v/)
- [Virtualization Blog](https://techcommunity.microsoft.com/t5/virtualization/bg-p/Virtualization)
- [MSLab GitHub Project](https://github.com/microsoft/MSLab)

## 🔧 Troubleshooting

### Common Issues

#### InvalidResourceLocation Error
If you see an error like:
```json
{
  "status": "Failed",
  "error": {
    "code": "InvalidResourceLocation",
    "message": "The specified location '[resourceGroup().location]' is invalid."
  }
}
```
**Solution**: In your parameter files (main.parameters.json and main.secure.parameters.json), replace `"[resourceGroup().location]"` with an actual Azure region name like `"swedencentral"` or `"westeurope"`. Parameter files require literal values, not ARM template expressions.

#### Script Errors
If the deployment scripts fail:
- Ensure Azure PowerShell or CLI is installed
- Check that you're logged into Azure with sufficient permissions
- Verify your subscription has capacity for the VM size you've selected
