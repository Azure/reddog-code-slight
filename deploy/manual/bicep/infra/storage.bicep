param storageAccountName string
param blobContainerName string
param keyVaultName string
param configStoreName string
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: blobService
  name: blobContainerName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName

  resource blobStorageAccount 'secrets' = {
    name: 'blob-storage-account'
    properties: {
      value: storageAccount.name
    }
  }

  resource blobStorageKey 'secrets' = {
    name: 'blob-storage-key'
    properties: {
      value: listkeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
    }
  }
}

resource configStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' existing = {
  name: configStoreName

  resource configStorageAccountName 'keyValues' = {
    name: 'AZURE_STORAGE_ACCOUNT'
    properties: {
      value: storageAccount.name
    }
  }

  resource configStorageAccountKey 'keyValues' = {
    name: 'AZURE_STORAGE_KEY'
    properties: {
      value: listkeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
    }
  }
}
