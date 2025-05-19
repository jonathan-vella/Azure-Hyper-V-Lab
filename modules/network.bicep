@description('Location for all resources.')
param location string

@description('Name prefix for all network resources')
param namingPrefix string

@description('Virtual Network(VNet) Configuration')
param vnetName string
param vnetaddressPrefix string
param subnetName string
param subnetPrefix string

@description('Deployment of Network Security Group(NSG)')
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${namingPrefix}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
  tags: {
    purpose: 'hyper-v-lab'
  }
}

@description('Deployment of Virtual Network(VNet)')
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${vnetName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetaddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
  tags: {
    purpose: 'hyper-v-lab'
  }
}

@description('Deployment of Public IP Address(PIP)')
resource vmPip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${namingPrefix}-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    deleteOption: 'Delete'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower(namingPrefix)
    }
  }
  tags: {
    purpose: 'hyper-v-lab'
  }
}

@description('Deployment of Network Interface Card(NIC)')
resource vmNic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${namingPrefix}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig01'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          publicIPAddress: {
            id: vmPip.id
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableIPForwarding: true
    networkSecurityGroup: {
      id: nsg.id
    }  }
  tags: {
    purpose: 'hyper-v-lab'
  }
}

// Outputs to be used by the VM module
output nicId string = vmNic.id
output pipId string = vmPip.id
output pipFqdn string = vmPip.properties.dnsSettings.fqdn
