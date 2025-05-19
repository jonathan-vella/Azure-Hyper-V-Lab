/*
  Hyper-V Lab Deployment in Azure
  This template deploys an Azure VM with nested virtualization enabled
  for running Hyper-V workloads in the cloud.
  
  Author: [Original by jonathan-vella, Modified to be modular]
  Last updated: 2025-05-19
*/

// Main template parameters
@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of Hyper-V Host Virtual Machine, Maximum of 15 characters, use letters and numbers only.')
@maxLength(15)
param computerName string

@description('Admin Username for the Host Virtual Machine')
param AdminUsername string

@description('Admin User Password for the Host Virtual Machine')
@secure()
param AdminPassword string

@description('Size of the Host Virtual Machine')
@allowed([
  'Standard_D2_v4'
  'Standard_D4_v4'
  'Standard_D8_v4'
  'Standard_D16_v4'
  'Standard_D32_v4'
  'Standard_D48_v4'
  'Standard_D64_v4'
  'Standard_D2s_v4'
  'Standard_D4s_v4'
  'Standard_D8s_v4'
  'Standard_D16s_v4'
  'Standard_D32s_v4'
  'Standard_D48s_v4'
  'Standard_D64s_v4'
  'Standard_D2_v5'
  'Standard_D4_v5'
  'Standard_D8_v5'
  'Standard_D16_v5'
  'Standard_D32_v5'
  'Standard_D48_v5'
  'Standard_D64_v5'
  'Standard_D2s_v5'
  'Standard_D4s_v5'
  'Standard_D8s_v5'
  'Standard_D16s_v5'
  'Standard_D32s_v5'
  'Standard_D48s_v5'
  'Standard_D64s_v5'
  'Standard_D2_v6'
  'Standard_D4_v6'
  'Standard_D8_v6'
  'Standard_D16_v6'
  'Standard_D32_v6'
  'Standard_D48_v6'
  'Standard_D64_v6'
  'Standard_D2s_v6'
  'Standard_D4s_v6'
  'Standard_D8s_v6'
  'Standard_D16s_v6'
  'Standard_D32s_v6'
  'Standard_D48s_v6'
  'Standard_D64s_v6'
  'Standard_D2_v3'
  'Standard_D4_v3'
  'Standard_D8_v3'
  'Standard_D16_v3'
  'Standard_D32_v3'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
  'Standard_D64s_v3'
  'Standard_E2_v3'
  'Standard_E4_v3'
  'Standard_E8_v3'
  'Standard_E16_v3'
  'Standard_E32_v3'
  'Standard_E64_v3'
  'Standard_E2s_v3'
  'Standard_E4s_v3'
  'Standard_E8s_v3'
  'Standard_E16s_v3'
  'Standard_E32s_v3'
  'Standard_E64s_v3'
  'Standard_E2_v4'
  'Standard_E4_v4'
  'Standard_E8_v4'
  'Standard_E16_v4'
  'Standard_E20_v4'
  'Standard_E32_v4'
  'Standard_E48_v4'
  'Standard_E64_v4'
  'Standard_E2s_v4'
  'Standard_E4s_v4'
  'Standard_E8s_v4'
  'Standard_E16s_v4'
  'Standard_E20s_v4'
  'Standard_E32s_v4'
  'Standard_E48s_v4'
  'Standard_E64s_v4'
  'Standard_E80s_v4'
  'Standard_F2s_v2'
  'Standard_F4s_v2'
  'Standard_F8s_v2'
  'Standard_F16s_v2'
  'Standard_F32s_v2'
  'Standard_F48s_v2'
  'Standard_F64s_v2'
  'Standard_F72s_v2'
  'Standard_M8ms'
  'Standard_M16ms'
  'Standard_M32ts'
  'Standard_M32ls'
  'Standard_M32ms'
  'Standard_M64s'
  'Standard_M64ls'
  'Standard_M64ms'
  'Standard_M128s'
  'Standard_M128ms'
  'Standard_M64'
  'Standard_M64m'
  'Standard_M128'
  'Standard_M128m'
])
param VirtualMachineSize string = 'Standard_D8s_v5'

@description('Virtual Network(VNet) Configuration')
param vnetName string = 'vnet-hypervlab-01'
param vnetaddressPrefix string = '192.168.0.0/24'
param subnetName string = 'snet-hypervlab-01'
param subnetPrefix string = '192.168.0.0/28'

// DSC and custom script configuration
@description('URL to the DSC configuration file. Update this with your own GitHub username when forking the repository.')
param dscFileUrl string = 'https://github.com/jonathan-vella/Azure-Hyper-V-Lab/raw/main/dsc/DSCInstallWindowsFeatures.zip'

@description('URL to the custom script file. Update this with your own GitHub username when forking the repository.')
param customScriptUrl string = 'https://raw.githubusercontent.com/jonathan-vella/Azure-Hyper-V-Lab/main/src/scripts/HostConfig.ps1'

// Deployment name - using unique naming for tracking (no runtime functions)
var deploymentNameSuffix = uniqueString(resourceGroup().id, computerName)

// Deploy network resources module
module networkResources '../../modules/network.bicep' = {
  name: '${computerName}-network-${deploymentNameSuffix}'
  params: {
    location: location
    namingPrefix: computerName
    vnetName: vnetName
    vnetaddressPrefix: vnetaddressPrefix
    subnetName: subnetName
    subnetPrefix: subnetPrefix
  }
}

// Deploy VM module
module hyperVHost '../../modules/vm.bicep' = {
  name: '${computerName}-vm-${deploymentNameSuffix}'
  params: {
    location: location
    computerName: computerName
    adminUsername: AdminUsername
    adminPassword: AdminPassword
    vmSize: VirtualMachineSize
    networkInterfaceId: networkResources.outputs.nicId
  }
}

// Deploy VM extensions module
module vmExtensions '../../modules/vm-extensions.bicep' = {
  name: '${computerName}-extensions-${deploymentNameSuffix}'
  params: {
    location: location
    vmName: hyperVHost.outputs.vmName
    dscFileUrl: dscFileUrl
    customScriptUrl: customScriptUrl
  }
}

// Outputs
output adminUsername string = AdminUsername
output hostname string = networkResources.outputs.pipFqdn != null ? networkResources.outputs.pipFqdn : 'No FQDN available'
output rdpCommand string = networkResources.outputs.pipFqdn != null ? 'mstsc.exe /v:${networkResources.outputs.pipFqdn}' : 'mstsc.exe /v:${computerName}'
