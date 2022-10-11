param location string = resourceGroup().location
param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param uniqueSuffix string = 'reddog-${uniqueString(uniqueSeed)}'
param userDefinedServicePrincipalAppId string = ''
param serviceBusNamespaceName string = 'sb-${uniqueSuffix}'
param keyVaultName string = 'kv-${uniqueSuffix}'
param configStoreName string = 'config-${uniqueSuffix}'
param redisName string = 'redis-${uniqueSuffix}'
//param cosmosAccountName string = 'cosmos-${uniqueSuffix}'
//param cosmosDatabaseName string = 'reddog'
//param cosmosCollectionName string = 'loyalty'
param storageAccountName string = 'st${replace(uniqueSuffix, '-', '')}'
param blobContainerName string = 'receipts'
param sqlServerName string = 'sql-${uniqueSuffix}'
param sqlDatabaseName string = 'reddog'
param sqlAdminLogin string = 'reddog'
@secure()
param sqlAdminLoginPassword string = take(newGuid(), 16)

module keyVaultModule 'infra/keyvault.bicep' = {
  name: '${deployment().name}--keyvault'
  params: {
    keyVaultName: keyVaultName
    userDefinedServicePrincipalAppId: userDefinedServicePrincipalAppId
    location: location
  }
}

module configModule 'infra/appconfiguration.bicep' = {
  name: '${deployment().name}--appconfiguration'
  params: {
    configStoreName: configStoreName
    location: location
  }
}

module serviceBusModule 'infra/servicebus.bicep' = {
  name: '${deployment().name}--servicebus'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    keyVaultName: keyVaultName
    configStoreName: configStoreName
    location: location
  }
}

module redisModule 'infra/redis.bicep' = {
  name: '${deployment().name}--redis'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    redisName: redisName
    keyVaultName: keyVaultName
    location: location
  }
}

/* Used for loyalty
module cosmosModule 'infra/cosmos.bicep' = {
  name: '${deployment().name}--cosmos'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    cosmosAccountName: cosmosAccountName
    cosmosDatabaseName: cosmosDatabaseName
    cosmosCollectionName: cosmosCollectionName
    location: location
  }
}
*/

module storageModule 'infra/storage.bicep' = {
  name: '${deployment().name}--storage'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    storageAccountName: storageAccountName
    blobContainerName: blobContainerName
    keyVaultName: keyVaultName
    configStoreName: configStoreName
    location: location
  }
}

module sqlServerModule 'infra/sqlserver.bicep' = {
  name: '${deployment().name}--sqlserver'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminLoginPassword: sqlAdminLoginPassword
    keyVaultName: keyVaultName
    location: location
  }
}
