# 🖥️ Guest VM Configuration & Setup Guide

This document describes the guest virtual machines (VMs) you will create inside your Azure Hyper-V Lab, along with their configuration and setup steps.

---

## 📋 Guest VM Overview

| Name   | Role                | CPU | Memory | Disk  | IP Address     | Notes                  |
|--------|---------------------|-----|--------|-------|----------------|------------------------|
| dc01   | Domain Controller   | 4   | 4 GB   | 64 GB | 172.16.0.10    | Promotes to ad.local   |
| sql01  | SQL Server          | 4   | 8 GB   | 64 GB | 172.16.0.11    | Joins ad.local domain  |
| web01  | Web Server (IIS)    | 4   | 8 GB   | 64 GB | 172.16.0.12    | Joins ad.local, IIS    |

- **Subnet:** 255.255.255.0
- **Gateway:** 172.16.0.1
- **Domain:** ad.local
- **Username:** demouser
- **Password:** demo!pass123

---

## 🛠️ Setup Steps

### 1. Create Guest VMs
- Use `Setup-GuestVMs.ps1` (auto-copied to `C:\temp` on the Azure VM) to create all three VMs with the correct specs and mount the Windows Server ISO.

### 2. Install Windows Server
- Start each VM in Hyper-V Manager.
- Install Windows Server 2025 from the mounted ISO.
- Set the computer name to match the VM (e.g., dc01).
- Use the provided username and password.

### 3. Configure Each VM
- After first login, copy the relevant setup script from `C:\temp` (on the host) to the guest VM, or run it directly if accessible.

#### • dc01
- Run `DC01-Setup.ps1` as Administrator.
- Configures static IP, installs AD DS & DNS, promotes to domain controller for `ad.local` (reboots).

#### • sql01
- Run `SQL01-Setup.ps1` as Administrator (after dc01 is promoted).
- Configures static IP, joins domain (reboots).

#### • web01
- Run `WEB01-Setup.ps1` as Administrator (after dc01 is promoted).
- Configures static IP, joins domain, installs IIS (reboots).

---

## ☕ Sample App Deployment
- To deploy the Brew Bliss Coffee Shop web app, see the [DEPLOY.md](./DEPLOY.md) for instructions.

---

## 🔗 References
- [DEPLOY.md](./DEPLOY.md): Full deployment guide
- [README.md](./README.md): Project overview
- [src/scripts/Save-GuestScripts.ps1](./src/scripts/Save-GuestScripts.ps1): Script generator
- [src/scripts/Setup-GuestVMs.ps1](./src/scripts/Setup-GuestVMs.ps1): VM creation script
