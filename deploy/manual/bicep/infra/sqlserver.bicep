param sqlServerName string
param sqlDatabaseName string
param location string
param sqlAdminLogin string
@secure()
param sqlAdminLoginPassword string
param keyVaultName string

resource sqlserver 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminLoginPassword
  }
}

resource sqlfirewall 'Microsoft.Sql/servers/firewallRules@2021-05-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlserver
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource database 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: sqlDatabaseName
  parent: sqlserver
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    autoPauseDelay: 60
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName

  resource sqlConnectionString 'secrets' = {
    name: 'reddog-sql'
    properties: {
      value: 'Server=tcp:${sqlserver.name}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${database.name};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    }
  }
}
