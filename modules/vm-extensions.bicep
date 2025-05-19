@description('Location for all resources.')
param location string

@description('The name of the VM resource')
param vmName string

@description('URL to the DSC configuration file. Update this with your own GitHub username when forking the repository.')
param dscFileUrl string = 'https://github.com/YOUR-USERNAME/Azure-Hyper-V-Lab/raw/main/dsc/DSCInstallWindowsFeatures.zip'

@description('URL to the custom script file. Update this with your own GitHub username when forking the repository.')
param customScriptUrl string = 'https://raw.githubusercontent.com/YOUR-USERNAME/Azure-Hyper-V-Lab/main/src/scripts/HostConfig.ps1'

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
