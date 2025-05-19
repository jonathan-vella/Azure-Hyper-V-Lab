@description('Location for all resources.')
param location string

@description('Name of Hyper-V Host Virtual Machine')
param computerName string

@description('Admin Username for the Host Virtual Machine')
param adminUsername string

@description('Admin User Password for the Host Virtual Machine')
@secure()
param adminPassword string

@description('Size of the Host Virtual Machine')
param vmSize string

@description('Network interface ID for the VM')
param networkInterfaceId string

@description('Deployment of Virtual Machine with Nested Virtualization')
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: computerName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2025-datacenter-g2'
        version: 'latest'
      }
      osDisk: {
        name: '${computerName}-OsDisk'
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        caching: 'ReadWrite'
      }
      dataDisks: [
        {
          lun: 0
          name: '${computerName}-DataDisk1'
          createOption: 'Empty'
          diskSizeGB: 512
          caching: 'ReadOnly'
          deleteOption: 'Delete'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      ]
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    priority: 'Spot'
    evictionPolicy: 'Deallocate'
    billingProfile: {
      maxPrice: -1
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceId
          properties: {
            primary: true
            deleteOption: 'Delete'
          }        
        }
      ]    }
  }
  tags: {
    purpose: 'hyper-v-lab'
  }
}

// Output the VM ID to be used by extensions
output vmId string = vm.id
output vmName string = vm.name
