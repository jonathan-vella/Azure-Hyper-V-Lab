## 🚀 Deployment Instructions

### 1. Deploy the Template
Click the button below to deploy the template directly in the Azure Portal:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjonathan-vella%2FAzure-Hyper-V-Lab%2Fmain%2Fsrc%2Fbicep%2Fmain.json)

### 2. Fill in the Required Information
Provide the necessary details in the Azure Portal:

- **Basic Settings**: Location, Resource Group, VM Name, and Admin credentials
- **VM Size**: Select the size of the VM (Standard_D8s_v5 recommended)
- **Bastion Settings**: 
  - **Deploy Bastion**: Set to 'true' to deploy Azure Bastion for secure RDP access
  - **Bastion SKU**: Choose 'Basic' for standard features or 'Standard' for additional features

![Template Configuration](./images/template.png)

### 3. Sit Back and Relax ☕
The deployment takes approximately 30 minutes.

![Deployment Progress](./images/deployment.png)

### 4. Connect to Your Hyper-V VM
Connect to your VM using **Azure Bastion** from the Azure Portal:

1. Navigate to the VM resource in the Azure Portal
2. Click on "Connect" in the top menu
3. Select "Bastion" as the connection method
4. Enter your VM credentials (username and password)
5. Click "Connect" to start the browser-based RDP session

Note: Azure Bastion provides secure RDP access without exposing a public IP address.

### 5. Manage Hyper-V Server
Start managing Hyper-V using **Hyper-V Manager** or **Windows Admin Center**.

![Hyper-V Shortcuts](./images/shortcuts.png)

### 6. Spin up Guest OS
Start creating Windows Server 2025 Guest OSes using the ISO file stored under `F:\VMS\ISO`.

![Windows Server 2025 Evaluation ISO](./images/iso.png)
