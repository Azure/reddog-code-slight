param redisName string
param keyVaultName string
param location string

resource redis 'Microsoft.Cache/redis@2020-12-01' = {
  name: redisName
  location: location
  properties: {
    sku: {
      name: 'Standard'
      family: 'C'
      capacity: 1
    }
    enableNonSslPort: false
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName

  resource redisServer 'secrets' = {
    name: 'redis-server'
    properties: {
      value: '${redis.properties.hostName}:${redis.properties.sslPort}'
    }
  }

  resource redisPassword 'secrets' = {
    name: 'redis-password'
    properties: {
      value: listKeys(redis.id, redis.apiVersion).primaryKey
    }
  }
}
