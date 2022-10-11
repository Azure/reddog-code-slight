import radius as radius

import kubernetes as kubernetes {
  kubeConfig: ''
  namespace: 'default'
}

param appId string
param environment string
param location string
param uniqueSeed string

param sqlServerName string = 'sql-${uniqueString(uniqueSeed)}'

@secure()
param sqlAdministratorLogin string
@secure()
param sqlAdministratorLoginPassword string

param accountingDbName string

// Azure SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
  }

  resource sqlServerFirewall 'firewallRules@2021-11-01-preview' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }

  resource accountingDb 'databases@2021-11-01-preview' = {
    name: accountingDbName
    location: location
    properties: {
      collation: 'SQL_Latin1_General_CP1_CI_AS'
    }
  }
}

// Radius App Connector
resource accountingDbConnector 'Applications.Connector/sqlDatabases@2022-03-15-privatepreview' = {
  name: 'accounting-db-connector'
  location: location
  properties: {
    application: appId
    environment: environment
    resource: sqlServer::accountingDb.id
  }
}

resource secret 'core/Secret@v1' = {
  metadata: {
    name: 'reddog-sql'
    namespace: 'reddog'
  }
  stringData: {
    'reddog-sql': 'Server=tcp:${sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Initial Catalog=${accountingDbName};Persist Security Info=False;User ID=${sqlAdministratorLogin};Password=${sqlAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

output accountingDbConnectorName string = accountingDbConnector.name
output sqlServerName string = sqlServerName
