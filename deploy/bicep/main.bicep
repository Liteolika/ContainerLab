targetScope = 'subscription'

@allowed([
  'swedencentral'
])
param location string

param containerRegistryName string
param containerRegistryResourceGroup string

var locationAbbreviations = {
  swedencentral: 'swc'
}
var locationAbbreviation = locationAbbreviations[location]

var systemName = 'myapp'
var env = 'dev'
var suffix = '${systemName}-${env}-${locationAbbreviation}'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${suffix}'
  location: location
}

resource registry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
  scope: resourceGroup(containerRegistryResourceGroup)
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'Deploy_KeyVault'
  scope: rg
  params: {
    name: 'kv-${suffix}'
    location: location
  }
}

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'Deploy_LogAnalytics'
  scope: rg
  params: {
    name: 'la--${suffix}'
    location: location
  }
}

module storage 'modules/storageAccount.bicep' = {
  name: 'Deploy_StorageAccount'
  scope: rg
  params: {
    name: uniqueString(rg.id, subscription().id)
    location: location
    shareName: 'shared'
    keyVaultName: keyVault.outputs.name
  }
}

module appEnv 'modules/appEnvironment.bicep' = {
  name: 'Deploy_AppEnv'
  scope: rg
  params: {
    name: 'env-${suffix}'
    location: location
    logAnalyticsCustomerId: logAnalytics.outputs.customerId
    logAnalyticsSharedKey: logAnalytics.outputs.primarySharedKey
    storageAccountName: storage.outputs.storageAccountName
    storageShareName: storage.outputs.shareName
    storageAccountKey: storage.outputs.accountKey
  }
}

module financeApp 'modules/containerApp.bicep' = {
  name: 'Deploy_FinanceApp'
  scope: rg
  params: {
    containerName: 'finance'
    location: location
    appEnvironmentId: appEnv.outputs.environmentId
    containerImage: '/testing/finance:v1'
    containerRegistryLoginServer: registry.properties.loginServer
    containerRegistryUser: registry.name
    containerRegistryPassword: registry.listCredentials().passwords[0].value
  }
}

module customerApp 'modules/containerApp.bicep' = {
  name: 'Deploy_CustomerApp'
  scope: rg
  params: {
    containerName: 'customer'
    location: location
    appEnvironmentId: appEnv.outputs.environmentId
    containerImage: '/testing/customer:v1'
    containerRegistryLoginServer: registry.properties.loginServer
    containerRegistryUser: registry.name
    containerRegistryPassword: registry.listCredentials().passwords[0].value
  }
}

output financeUrl string = financeApp.outputs.fqdn
output customerUrl string = customerApp.outputs.fqdn

