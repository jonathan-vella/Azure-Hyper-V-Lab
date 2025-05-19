@description('Location for all resources.')
param location string

@description('Name prefix for all network resources')
param namingPrefix string

@description('Virtual Network(VNet) Configuration')
param vnetName string
param vnetaddressPrefix string
param subnetName string
param subnetPrefix string

@description('Bastion Subnet Configuration')
param bastionSubnetPrefix string = '192.168.0.128/26' // Using default value
param deployBastion bool = true // Default to deploy Bastion
@allowed([
  'Basic'
  'Standard'
])
param bastionSku string = 'Basic' // Default to Basic SKU

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
      {
        name: 'AzureBastionSubnet' // Required name for Bastion
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
    ]
  }
  tags: {
    purpose: 'hyper-v-lab'
  }
}

@description('Deployment of Public IP Address for Azure Bastion')
resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (deployBastion) {
  name: '${namingPrefix}-bastion-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${namingPrefix}-bastion')
    }
  }
  tags: {
    purpose: 'hyper-v-lab'
  }
}

@description('Deployment of Azure Bastion')
resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = if (deployBastion) {
  name: '${namingPrefix}-bastion'
  location: location
  sku: {
    name: bastionSku
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', '${vnetName}-vnet', 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
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
output bastionEnabled bool = deployBastion
output bastionName string = deployBastion ? bastion.name : 'Not deployed'
output bastionFqdn string = deployBastion ? bastionPip.properties.dnsSettings.domainNameLabel : 'No Bastion deployed'
// Reference the private IP that is assigned during deployment
output vmPrivateIp string = vmNic.properties.ipConfigurations[0].properties.privateIPAddress
