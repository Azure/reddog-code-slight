param serviceBusNamespaceName string
param keyVaultName string
param configStoreName string
param location string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName

  resource sbRootConnectionString 'secrets' = {
    name: 'sb-root-connectionstring'
    properties: {
      value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
    }
  }
}

resource configStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' existing = {
  name: configStoreName

  resource configServiceBusNamespace 'keyValues' = {
    name: 'AZURE_SERVICE_BUS_NAMESPACE'
    properties: {
      value: serviceBus.name
    }
  }

  resource configServiceBusPolicyName 'keyValues' = {
    name: 'AZURE_POLICY_NAME'
    properties: {
      value: 'RootManageSharedAccessKey'
    }
  }

  resource configServiceBusPolicyKey 'keyValues' = {
    name: 'AZURE_POLICY_KEY'
    properties: {
      value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryKey
    }
  }
}
