param name string
param location string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      
    ]
    tenantId: tenant().tenantId
  }
}

output name string = keyVault.name
