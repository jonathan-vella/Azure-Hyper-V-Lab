# Quick Start Guide: Hyper-V Lab Deployment

This guide will help you quickly deploy the Hyper-V Lab environment using our modular Bicep templates.

## Prerequisites

- Azure Subscription
- Azure PowerShell or Azure CLI installed
- Git (to clone the repository)

## Option 1: PowerShell Deployment (Windows)

### 1. Clone the Repository
```powershell
git clone https://github.com/YOUR-USERNAME/Azure-Hyper-V-Lab.git
cd Azure-Hyper-V-Lab
```

### 2. Run the Deployment Script
```powershell
# Connect to Azure (if not already connected)
Connect-AzAccount

# Run the deployment with default values (except password)
.\Deploy-HyperVLab.ps1 -AdminPassword (ConvertTo-SecureString -String 'YourSecurePassword123!' -AsPlainText -Force)

# Or with custom values
.\Deploy-HyperVLab.ps1 -ResourceGroupName "MyHyperVLab" `
                       -Location "swedencentral" `
                       -ComputerName "hyperv01" `
                       -AdminUsername "labadmin" `
                       -VmSize "Standard_D16s_v5" `
                       -AdminPassword (ConvertTo-SecureString -String 'YourSecurePassword123!' -AsPlainText -Force)
```

## Option 2: Azure CLI Deployment (Cross-platform)

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR-USERNAME/Azure-Hyper-V-Lab.git
cd Azure-Hyper-V-Lab
```

### 2. Run the Deployment Script
```bash
# Make the script executable (Linux/macOS)
chmod +x ./src/scripts/deploy-hyperv-lab.sh

# Connect to Azure (if not already connected)
az login

# Run the deployment with default values (except password)
./src/scripts/deploy-hyperv-lab.sh --password 'YourSecurePassword123!'

# Or with custom values
./src/scripts/deploy-hyperv-lab.sh --resource-group "MyHyperVLab" \
                      --location "swedencentral" \
                      --name "hyperv01" \
                      --username "labadmin" \
                      --vm-size "Standard_D16s_v5" \
                      --password 'YourSecurePassword123!'
```

## Option 3: Manual Deployment

### 1. Deploy Using Azure Portal
- Click the "Deploy to Azure" button in the README
- Fill in the required parameters
- Click "Review + create" and then "Create"

### 2. Deploy Using Command Line with Parameter File
```powershell
# PowerShell
# Edit src/parameters/main.parameters.json first with your preferred settings
New-AzResourceGroupDeployment -ResourceGroupName "MyHyperVLab" -TemplateFile ".\src\bicep\main.bicep" -TemplateParameterFile ".\src\parameters\main.parameters.json"
```

```bash
# Azure CLI
# Edit src/parameters/main.parameters.json first with your preferred settings
az deployment group create --resource-group "MyHyperVLab" --template-file "./src/bicep/main.bicep" --parameters "@src/parameters/main.parameters.json"
```

## Troubleshooting

If you encounter issues during deployment:

1. Check the [Troubleshooting section](README.md#troubleshooting) in the main README
2. Validate your templates with: `.\Validate-Templates.ps1`
3. Verify parameter values in main.parameters.json have proper formatting

## After Deployment

1. Wait for the deployment to complete (approximately 30 minutes)
2. Connect to the VM using RDP with the provided credentials
3. Start using Hyper-V Manager to create your virtual machines

For more detailed information, refer to the [Modular Template Guide](MODULAR-TEMPLATE-GUIDE.md).
