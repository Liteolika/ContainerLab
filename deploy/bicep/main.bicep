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

var systemName = 'labsystem'
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

module appIdentity 'modules/identity.bicep' = {
  name: 'Deploy_AppIdentity'
  scope: rg
  params: {
    location: location
    name: 'id-${suffix}'
  }
}

module roleAssignment 'modules/containerRegistryRoleAssignment.bicep' = {
  name: 'container-registry-role-assignment'
  scope: resourceGroup(containerRegistryResourceGroup)
  params: {
    // https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
    roleId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    principalId: appIdentity.outputs.principalId
    registryName: containerRegistryName
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'Deploy_KeyVault'
  scope: rg
  params: {
    name: 'kv-${suffix}'
    location: location
    principalId: appIdentity.outputs.principalId
    tenantId: subscription().tenantId
  }
}

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'Deploy_LogAnalytics'
  scope: rg
  params: {
    name: 'la-${suffix}'
    location: location
  }
}

module storage 'modules/storageAccount.bicep' = {
  name: 'Deploy_StorageAccount'
  scope: rg
  params: {
    name: 'storage${uniqueString(rg.id, subscription().id)}'
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

module appInsights 'modules/appInsights.bicep' = {
  name: 'Deploy_Application_Insights'
  scope: rg
  params: {
    name: 'ai-${suffix}'
    location: location
    workspaceResourceId: logAnalytics.outputs.id
  }
}

module financeApp 'modules/containerApp.bicep' = {
  name: 'Deploy_FinanceApp'
  scope: rg
  params: {
    containerName: 'finance'
    location: location
    appEnvironmentId: appEnv.outputs.environmentId
    containerImage: '/testing/finance:latest'
    containerRegistryLoginServer: registry.properties.loginServer
    identityId: appIdentity.outputs.id
    env: [
      {
        name: 'KeyVaultName'
        value: keyVault.outputs.name
      }
      {
        name: 'AzureADManagedIdentityClientId'
        value: appIdentity.outputs.clientId
      }
      {
        name: 'ApplicationInsights__ConnectionString'
        value: appInsights.outputs.connectionString
      }
    ]
    // containerRegistryUser: registry.name
    // containerRegistryPassword: registry.listCredentials().passwords[0].value
  }
}

module customerApp 'modules/containerApp.bicep' = {
  name: 'Deploy_CustomerApp'
  scope: rg
  params: {
    containerName: 'customer'
    location: location
    appEnvironmentId: appEnv.outputs.environmentId
    containerImage: '/testing/customer:latest'
    containerRegistryLoginServer: registry.properties.loginServer
    identityId: appIdentity.outputs.id
    env: [
      {
        name: 'KeyVaultName'
        value: keyVault.outputs.name
      }
      {
        name: 'AzureADManagedIdentityClientId'
        value: appIdentity.outputs.clientId
      }
      {
        name: 'ApplicationInsights__ConnectionString'
        value: appInsights.outputs.connectionString
      }
    ]
    // containerRegistryUser: registry.name
    // containerRegistryPassword: registry.listCredentials().passwords[0].value
  }
}

output financeUrl string = financeApp.outputs.fqdn
output customerUrl string = customerApp.outputs.fqdn
