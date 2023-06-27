param name string
param location string
param shareName string
param keyVaultName string

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }

}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  name: 'default'
  parent: storage
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: false
      days: 0
    }
  }
}

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: shareName
  parent: fileServices
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 5120
    enabledProtocols: 'SMB'
  }

}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: '${keyVaultName}/storageAccountKey'
  properties: {
    value: storage.listKeys().keys[0].value
  }
}

output storageAccountName string = storage.name
output shareName string = share.name
output accountKey string = storage.listKeys().keys[0].value

