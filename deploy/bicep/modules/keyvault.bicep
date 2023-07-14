param name string
param location string
param principalId string
param tenantId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    createMode: 'default' // This should be set to 'recover' if production env.
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: principalId
        permissions: {
          certificates: [
            'get'
            'list'
          ]
          keys: [
            'get'
            'list'
          ]
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    tenantId: tenant().tenantId
  }
}

output name string = keyVault.name
