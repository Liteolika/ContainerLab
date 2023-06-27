param name string
param location string
param logAnalyticsCustomerId string
param logAnalyticsSharedKey string

param storageAccountName string
param storageShareName string
@secure()
param storageAccountKey string

resource environment 'Microsoft.App/managedEnvironments@2023-04-01-preview' = {
  name: name
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
  }
}

resource azureFileStorage 'Microsoft.App/managedEnvironments/storages@2023-04-01-preview' = {
  name: 'environmentstorage'
  parent: environment
  properties: {
    azureFile: {
      accountName: storageAccountName
      shareName: storageShareName
      accessMode: 'ReadWrite'
      accountKey: storageAccountKey
    }
  }
}

output environmentId string = environment.id
