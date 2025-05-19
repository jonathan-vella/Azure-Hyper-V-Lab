@description('Location for all resources.')
param location string

@description('The name of the VM resource')
param vmName string

@description('Extension dependencies')
param dscFileUrl string = 'https://github.com/jonathan-vella/Azure-Hyper-V-Lab/raw/main/dsc/DSCInstallWindowsFeatures.zip'
param customScriptUrl string = 'https://raw.githubusercontent.com/jonathan-vella/Azure-Hyper-V-Lab/main/HostConfig.ps1'

@description('Deployment of DSC Configuration. Enablement of Hyper-V and DHCP Roles along with RSAT Tools.')
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: '${vmName}/InstallWindowsFeatures'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: dscFileUrl
        script: 'DSCInstallWindowsFeatures.ps1'
        function: 'InstallWindowsFeatures'
      }
    }
  }
}

@description('Custom Script Execution. Configuration of Server Roles, installation of Chocolatey and deployment of software.')
resource hostVmSetupExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: '${vmName}/HostConfiguration'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptUrl
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File HostConfig.ps1'
    }
  }
  dependsOn: [
    vmExtension
  ]
}

// Outputs
output dscExtensionId string = vmExtension.id
output customScriptExtensionId string = hostVmSetupExtension.id
