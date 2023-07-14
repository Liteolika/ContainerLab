param location string
param name string

@description('VNET Address Space (CIDR notation, /23 or greater)')
param vnetAddressSpace string = '10.0.0.0/16'

@description('Subnet resource name')
param containerAppSubnetName string = 'defaultSubnet'

@description('Subnet Address Prefix (CIDR notation, /23 or greater)')
param subnetAddressPrefix string = '10.0.0.0/21'

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetAddressSpace ]
    }
  }

  resource subnet 'subnets@2022-01-01' = {
    name: containerAppSubnetName
    properties: {
      addressPrefix: subnetAddressPrefix
      serviceEndpoints: [
        {
          service: 'Microsoft.Storage'
          locations: [ location ]
        }
      ]
    }
  }
}

output subnetId string = vnet::subnet.id
