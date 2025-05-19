# Modular Bicep Template Documentation

This document provides details on the modular Bicep template structure used for deploying the Azure Hyper-V Lab.

## Template Structure

The Azure Hyper-V Lab template has been modularized for better maintainability, reusability, and readability. The structure consists of:

```
├── src/                        # Source code folder
│   ├── bicep/                  # Bicep templates
│   │   ├── main.bicep          # Main deployment template
│   │   └── main.json           # ARM template (compiled from main.bicep)
│   ├── parameters/             # Parameter files
│   │   ├── main.parameters.json        # Parameter file for development deployments
│   │   └── main.secure.parameters.json # Parameter file with Key Vault reference
│   └── scripts/                # Deployment and utility scripts
│       ├── Check-ParameterFiles.ps1    # Parameter file validation
│       ├── deploy-hyperv-lab.sh        # Bash deployment script
│       ├── Deploy-HyperVLab.ps1        # PowerShell deployment script
│       ├── HostConfig.ps1              # Custom script for VM configuration
│       ├── Test-Deployment.ps1         # Deployment testing script
│       ├── Update-GitHubUrls.ps1       # GitHub URL updater
│       └── Validate-Templates.ps1      # Template validation script
├── modules/                    # Folder containing all module files
│   ├── network.bicep           # Network resources (VNet, NSG, PIP, NIC)
│   ├── vm.bicep                # Virtual Machine configuration
│   └── vm-extensions.bicep     # VM extensions (DSC, Custom Script)
├── dsc/                        # DSC configuration files
│   └── DSCInstallWindowsFeatures.zip
├── images/                     # Documentation images
├── README.md                   # Main documentation
├── QUICKSTART.md               # Quick start guide
└── MODULAR-TEMPLATE-GUIDE.md   # This document
```

## Module Responsibilities

### 1. Network Module (`modules/network.bicep`)

This module handles the deployment of all networking resources:
- Network Security Group (NSG) with RDP access rule
- Virtual Network (VNet) with subnet
- Public IP Address with static allocation
- Network Interface Card (NIC)

**Outputs:**
- `nicId`: The resource ID of the network interface
- `pipId`: The resource ID of the public IP address
- `pipFqdn`: The fully qualified domain name of the public IP

### 2. VM Module (`modules/vm.bicep`)

This module handles the virtual machine deployment:
- VM with Windows Server 2025 Datacenter
- OS and data disks configuration
- Security profile with Trusted Launch
- Spot instance configuration for cost optimization

**Outputs:**
- `vmId`: The resource ID of the virtual machine
- `vmName`: The name of the virtual machine

### 3. VM Extensions Module (`modules/vm-extensions.bicep`)

This module deploys extensions that configure the VM:
- DSC extension for installing Hyper-V and DHCP roles
- Custom Script Extension for software installation and configuration

**Outputs:**
- `dscExtensionId`: The resource ID of the DSC extension
- `customScriptExtensionId`: The resource ID of the custom script extension

## Deployment Options

### PowerShell Deployment

```powershell
# Clone the repository
git clone https://github.com/jonathan-vella/Azure-Hyper-V-Lab.git
cd Azure-Hyper-V-Lab

# Deploy using PowerShell script
.\Deploy-HyperVLab.ps1 -ResourceGroupName "MyHyperVLab" -Location "swedencentral" -AdminPassword (ConvertTo-SecureString -String "YourStrongPassword" -AsPlainText -Force)
```

### Azure CLI Deployment

```bash
# Create a resource group
az group create --name MyHyperVLab --location swedencentral

# Deploy the Bicep template
az deployment group create \
  --resource-group MyHyperVLab \
  --template-file src/bicep/main.bicep \
  --parameters computerName=hypervhost AdminUsername=azureuser AdminPassword=YourStrongPassword
```

### Using Parameter Files

```powershell
# Using the parameter file
New-AzResourceGroupDeployment -ResourceGroupName "MyHyperVLab" -TemplateFile ".\src\bicep\main.bicep" -TemplateParameterFile ".\src\parameters\main.parameters.json"
```

> **Important Note**: Always ensure the `location` parameter in parameter files contains an actual Azure region name (like "swedencentral" or "westeurope"), not an ARM template expression like `[resourceGroup().location]`. Parameter files require literal values.

### Production Deployment with Key Vault

For secure production deployments, use the `main.secure.parameters.json` file which references a password stored in Azure Key Vault:

1. Create a Key Vault and add your password as a secret:
```powershell
# Create a Key Vault
New-AzKeyVault -Name "MyHyperVLabKeyVault" -ResourceGroupName "MyHyperVLab-RG" -Location "swedencentral" -EnabledForTemplateDeployment

# Add a secret
$secretValue = ConvertTo-SecureString -String "YourStrongPassword" -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName "MyHyperVLabKeyVault" -Name "HyperVLabAdminPassword" -SecretValue $secretValue
```

2. Update the `main.secure.parameters.json` file with your Key Vault details

3. Deploy using the secure parameter file:
```powershell
New-AzResourceGroupDeployment -ResourceGroupName "MyHyperVLab-RG" -TemplateFile ".\src\bicep\main.bicep" -TemplateParameterFile ".\src\parameters\main.secure.parameters.json"
```

## Customization Options

The modular structure allows for easy customization:

- **Network Configuration**: Modify the `network.bicep` file to change network settings
- **VM Size and Configuration**: Adjust the `vm.bicep` file to change VM specifications
- **Extensions and Software**: Update the `vm-extensions.bicep` file to modify the installed software

## Extending the Template

To add new features:

1. Create a new module file in the `modules` folder
2. Reference the module in `main.bicep`
3. Add any required parameters to `main.parameters.json`

## Best Practices Used

This template follows Azure best practices:

- **Modularity**: Components are separated into reusable modules
- **Naming Conventions**: Consistent naming patterns across resources
- **Resource Dependencies**: Explicit dependencies between resources
- **Tags**: All resources are tagged for better management
- **Parameters**: Sensible defaults with parameter validation
- **Security**: Trusted Launch enabled for enhanced VM security
- **Cost Optimization**: Using Spot instances for cost savings

## Utilities and Tools

The repository includes several utility scripts to help with the deployment process:

### Update-GitHubUrls.ps1

When forking this repository, you'll need to update all GitHub URLs to point to your own repository. This script automates that process:

```powershell
# Example: Update GitHub URLs to use your username
.\src\scripts\Update-GitHubUrls.ps1 -GitHubUsername "your-github-username"
```

### Check-ParameterFiles.ps1

Validates parameter files to ensure they don't contain ARM template expressions where literal values are expected:

```powershell
# Check all parameter files
.\src\scripts\Check-ParameterFiles.ps1
```

### Validate-Templates.ps1

Performs a more thorough validation of all Bicep templates:

```powershell
# Validate all templates
.\src\scripts\Validate-Templates.ps1
```

### Test-Deployment.ps1

Tests the deployment without actually creating resources:

```powershell
# Test deployment
.\src\scripts\Test-Deployment.ps1 -ResourceGroupName "TestRG"
```
