param name string
param location string


resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
}

output principalId string = identity.properties.principalId
output id string = identity.id
output clientId string = identity.properties.clientId
