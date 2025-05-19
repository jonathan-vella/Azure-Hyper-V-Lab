# 🧩 Modular Bicep Template Guide

Welcome! This guide explains the modular Bicep structure powering your Azure Hyper-V Lab. Use the navigation below to jump to any section.

- [Template Structure](#template-structure)
- [Module Responsibilities](#module-responsibilities)
- [Brew Bliss Coffee Shop Web App](#-brew-bliss-coffee-shop-web-application)
- [Deployment Options](#deployment-options)
- [Customization & Extending](#customization-options)
- [Best Practices](#best-practices-used)
- [Utilities & Tools](#utilities-and-tools)

---

## 📦 Template Structure

The Azure Hyper-V Lab template is modular for maintainability, reusability, and clarity:

```
├── src/
│   ├── bicep/           # Bicep templates
│   │   ├── main.bicep   # Main deployment template
│   │   └── main.json    # ARM template (compiled)
│   ├── parameters/      # Parameter files
│   └── scripts/         # Deployment & utility scripts
│       ├── ...
│       └── HostConfig.ps1
│   └── eshop/           # Sample web app & deployment script
├── modules/             # All Bicep modules
│   ├── network.bicep
│   ├── vm.bicep
│   └── vm-extensions.bicep
├── dsc/                 # DSC configuration
├── images/              # Documentation images
├── README.md            # Main documentation
├── QUICKSTART.md        # Quick start guide
└── MODULAR-TEMPLATE-GUIDE.md   # This document
```

---

## 🏗️ Module Responsibilities

### 1. **Network Module** (`modules/network.bicep`)
- Deploys: NSG (with RDP), VNet, Subnet, Public IP, NIC
- **Outputs:** `nicId`, `pipId`, `pipFqdn`

### 2. **VM Module** (`modules/vm.bicep`)
- Deploys: Windows Server 2025 VM, OS/data disks, Trusted Launch, Spot instance
- **Outputs:** `vmId`, `vmName`

### 3. **VM Extensions Module** (`modules/vm-extensions.bicep`)
- Deploys: DSC extension (Hyper-V, DHCP), Custom Script Extension (software/config)
- **Outputs:** `dscExtensionId`, `customScriptExtensionId`

---

## ☕ Brew Bliss Coffee Shop Web Application

- **Location:** `src/eshop/`
  - `CoffeeShopWebDeploy.zip`: Web app package
  - `Deploy-CoffeeShop.ps1`: PowerShell deployment script
- **How to use:** The deployment script is auto-copied to `C:\temp` on the Azure VM for easy access. See the main deployment guide for usage.

---

## 🚀 Deployment Options

### PowerShell
```powershell
# Clone the repo
 git clone https://github.com/jonathan-vella/Azure-Hyper-V-Lab.git
 cd Azure-Hyper-V-Lab
# Deploy
 .\Deploy-HyperVLab.ps1 -ResourceGroupName "MyHyperVLab" -Location "swedencentral" -AdminPassword (ConvertTo-SecureString -String "demo!pass123" -AsPlainText -Force)
```

### Azure CLI
```bash
az group create --name MyHyperVLab --location swedencentral
az deployment group create \
  --resource-group MyHyperVLab \
  --template-file src/bicep/main.bicep \
  --parameters computerName=hypervhost AdminUsername=demouser AdminPassword='demo!pass123'
```

### Using Parameter Files
```powershell
New-AzResourceGroupDeployment -ResourceGroupName "MyHyperVLab" -TemplateFile ".\src\bicep\main.bicep" -TemplateParameterFile ".\src\parameters\main.parameters.json"
```
> **Note:** Parameter files require literal region names (e.g., `swedencentral`).

### Production Deployment with Key Vault
1. Create a Key Vault and add your password as a secret:
   ```powershell
   New-AzKeyVault -Name "MyHyperVLabKeyVault" -ResourceGroupName "MyHyperVLab-RG" -Location "swedencentral" -EnabledForTemplateDeployment
   $secretValue = ConvertTo-SecureString -String "demo!pass123" -AsPlainText -Force
   Set-AzKeyVaultSecret -VaultName "MyHyperVLabKeyVault" -Name "HyperVLabAdminPassword" -SecretValue $secretValue
   ```
2. Update `main.secure.parameters.json` with your Key Vault details
3. Deploy:
   ```powershell
   New-AzResourceGroupDeployment -ResourceGroupName "MyHyperVLab-RG" -TemplateFile ".\src\bicep\main.bicep" -TemplateParameterFile ".\src\parameters\main.secure.parameters.json"
   ```

---

## 🛠️ Customization & Extending

- **Network:** Edit `network.bicep` for VNet, NSG, etc.
- **VM Size/Config:** Edit `vm.bicep` for VM specs
- **Extensions/Software:** Edit `vm-extensions.bicep` for installed software
- **Add Features:**
  1. Create a new module in `modules/`
  2. Reference it in `main.bicep`
  3. Add parameters as needed

---

## 🏅 Best Practices Used
- **Modularity:** Reusable, organized modules
- **Naming:** Consistent resource names
- **Dependencies:** Explicit resource dependencies
- **Tags:** All resources tagged
- **Parameters:** Sensible defaults, validation
- **Security:** Trusted Launch, Key Vault support
- **Cost:** Spot instances for savings

---

## 🧰 Utilities and Tools

### Update-GitHubUrls.ps1
Update all GitHub URLs after forking:
```powershell
.\src\scripts\Update-GitHubUrls.ps1 -GitHubUsername "your-github-username"
```

### Check-ParameterFiles.ps1
Validate parameter files:
```powershell
.\src\scripts\Check-ParameterFiles.ps1
```

### Validate-Templates.ps1
Validate all Bicep templates:
```powershell
.\src\scripts\Validate-Templates.ps1
```

### Test-Deployment.ps1
Test deployment (no resources created):
```powershell
.\src\scripts\Test-Deployment.ps1 -ResourceGroupName "TestRG"
```

---

**For a quick start, see [QUICKSTART.md](./QUICKSTART.md). For full deployment, see [DEPLOY.md](./DEPLOY.md).**
