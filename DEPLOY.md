# 🚀 Azure Hyper-V Lab: End-to-End Deployment Guide

Welcome! This guide will walk you through deploying your Azure Hyper-V Lab, setting up nested guest VMs, and deploying the Brew Bliss Coffee Shop web app. Each step is clear, concise, and easy to follow.

---

## 1️⃣ Deploy the Azure Hyper-V Lab Template

**Quick Start:**
- Click the button below to deploy in the Azure Portal:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjonathan-vella%2FAzure-Hyper-V-Lab%2Fmain%2Fsrc%2Fbicep%2Fmain.json)

**Fill in the Required Information:**
- **Location, Resource Group, VM Name, Admin credentials**
- **VM Size:** Standard_D8s_v5 recommended
- **Bastion:**
  - Deploy Bastion: `true` for secure RDP
  - Bastion SKU: `Basic` or `Standard`

![Template Configuration](./images/template.png)

---

## 2️⃣ Wait for Deployment

- Deployment takes ~30 minutes.
- Watch progress in the Azure Portal.

![Deployment Progress](./images/deployment.png)

---

## 3️⃣ Connect to Your Hyper-V VM

- In the Azure Portal, go to your VM resource
- Click **Connect** > **Bastion**
- Enter your credentials and connect

> **Tip:** Azure Bastion provides secure RDP without a public IP.

---

## 4️⃣ Manage Hyper-V

- Use **Hyper-V Manager** or **Windows Admin Center** (shortcuts on desktop)

![Hyper-V Shortcuts](./images/shortcuts.png)

---

## 5️⃣ Create & Configure Guest VMs

### a. Guest VM Setup Scripts
Scripts are auto-copied to `C:\temp`:
- `Setup-GuestVMs.ps1` — Create guest VMs
- `DC01-Setup.ps1` — Domain controller config
- `SQL01-Setup.ps1` — SQL server domain join
- `WEB01-Setup.ps1` — Web server domain join + IIS

### b. Create the Guest VMs
1. Open PowerShell as Administrator on the Azure VM
2. Run:
   ```powershell
   cd C:\temp
   .\Setup-GuestVMs.ps1
   ```
   - This creates `dc01`, `sql01`, `web01` (not started)
   - ISO: `F:\VMS\ISO\WindowsServer2025Eval.iso`

### c. Install Windows Server on Each Guest VM
1. Open **Hyper-V Manager**
2. For each VM:
   - Connect, start, and install Windows Server 2025
   - Set computer name: `dc01`, `sql01`, or `web01`
   - Credentials:
     - **Username:** `demouser`
     - **Password:** `demo!pass123`

### d. Configure Each Guest VM
After first login as `demouser`:

- **On `dc01`:**
  1. Run `DC01-Setup.ps1` from `C:\temp` (as Administrator)
     ```powershell
     .\DC01-Setup.ps1
     ```
  2. Sets static IP, installs AD DS & DNS, promotes to domain controller (`ad.local`). VM will reboot.

- **On `sql01`:**
  1. After `dc01` is promoted, run `SQL01-Setup.ps1` (as Administrator)
     ```powershell
     .\SQL01-Setup.ps1
     ```
  2. Sets static IP, joins domain. VM will reboot.

- **On `web01`:**
  1. After `dc01` is promoted, run `WEB01-Setup.ps1` (as Administrator)
     ```powershell
     .\WEB01-Setup.ps1
     ```
  2. Sets static IP, joins domain, installs IIS. VM will reboot.

> **Tip:** Use Enhanced Session Mode or RDP for easy copy/paste between host and guests.

---

## 6️⃣ Deploy the Brew Bliss Coffee Shop Web App

- Files in `C:\temp`:
  - `CoffeeShopWebDeploy.zip` (web app)
  - `Deploy-CoffeeShop.ps1` (deployment script)

### a. Copy Files to the Target VM
- Choose a VM to host the app (usually `web01`)
- Copy both files from `C:\temp` on the Azure VM host to the guest VM

### b. Deploy the App
1. Log in to the guest VM as `demouser`
2. Open PowerShell as Administrator
3. Run:
   ```powershell
   cd C:\temp
   .\Deploy-CoffeeShop.ps1
   ```
4. Open a browser on the guest VM and go to `http://localhost` to verify the app is running

---

## 7️⃣ (Optional) Explore & Customize
- Use Windows Admin Center for advanced management
- Use Azure Storage Explorer and AzCopy for storage
- Explore included tools and scripts for more options

---

## 🎉 All Done!
You now have a fully functional nested Hyper-V lab in Azure, with a domain, SQL server, web server, and a sample web app.

For troubleshooting, see [README.md](./README.md) or open an issue in the repository.
