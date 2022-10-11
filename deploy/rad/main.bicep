import radius as radius

param environment string

param location string = resourceGroup().location
param uniqueSeed string = resourceGroup().id

param sqlAdministratorLogin string = 'server_admin'
@secure()
param sqlAdministratorLoginPassword string = 'Str0ngPass@word'
param accountingDbName string = 'reddog'

resource app 'Applications.Core/applications@2022-03-15-privatepreview' = {
  name: 'reddog'
  location: 'global'
  properties: {
    environment: environment
  }
}

///////////////////////////////////////////////////////////////////////////////
// Infrastructure
///////////////////////////////////////////////////////////////////////////////

// Azure SQL Database
module sqlServer 'infra/azure-sqlserver.bicep' = {
  name: '${deployment().name}-sql'
  params: {
    appId: app.id
    environment: environment
    location: location
    uniqueSeed: uniqueSeed
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    accountingDbName: accountingDbName
  }
}

// Dapr Pub/Sub Broker
module pubSub 'infra/dapr-pub-sub.bicep' = {
  name: '${deployment().name}-dapr-pubsub'
  params: {
    appId: app.id
    environment: environment
    location: location
    uniqueSeed: uniqueSeed
  }
}

// Dapr State Store
module stateStore 'infra/dapr-state-store.bicep' = {
  name: '${deployment().name}-dapr-state-store'
  params: {
    appId: app.id
    environment: environment
    location: location
    uniqueSeed: uniqueSeed
  }
}

// HTTP Routes and Gateway
module httpRoutes 'infra/routes-and-gateway.bicep' = {
  name: '${deployment().name}-routes-and-gateway'
  params: {
    appId: app.id
  }
}


///////////////////////////////////////////////////////////////////////////////
// Services
///////////////////////////////////////////////////////////////////////////////

module virtualCustomers 'services/virtual-customers.bicep' = {
  name: '${deployment().name}-virtual-customers'
  params: {
    appId: app.id
    environment: environment
    orderServiceDaprRouteName: orderService.outputs.orderServiceDaprRouteName
  }
}

module bootstrapper 'services/bootstrapper.bicep' = {
  name: '${deployment().name}-bootstrapper'
  params: {
    appId: app.id
    sqlConnectionString: 'Server=tcp:${sqlServer.outputs.sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Initial Catalog=${accountingDbName};Persist Security Info=False;User ID=${sqlAdministratorLogin};Password=${sqlAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

module ui 'services/ui.bicep' = {
  name: '${deployment().name}-ui'
  params: {
    appId: app.id
    daprPubSubBrokerName: pubSub.outputs.daprPubSubBrokerName
    uiRouteName: httpRoutes.outputs.uiRouteName
    makelineServiceDaprRouteName: makelineService.outputs.makelineServiceDaprRouteName
    accountingServiceDaprRouteName: accountingService.outputs.accountingServiceDaprRouteName
  }
}

module orderService 'services/order-service.bicep' = {
  name: '${deployment().name}-order-service'
  params: {
    appId: app.id
    environment: environment
    daprPubSubBrokerName: pubSub.outputs.daprPubSubBrokerName
  }
}

module makelineService 'services/make-line-service.bicep' = {
  name: '${deployment().name}-make-line-service'
  params: {
    appId: app.id
    environment: environment
    daprPubSubBrokerName: pubSub.outputs.daprPubSubBrokerName
    daprStateStoreName: stateStore.outputs.daprStateStoreName
  }
}

module accountingService 'services/accounting-service.bicep' = {
  name: '${deployment().name}-accounting-service'
  params: {
    appId: app.id
    environment: environment
    daprPubSubBrokerName: pubSub.outputs.daprPubSubBrokerName
    sqlConnectionString: 'Server=tcp:${sqlServer.outputs.sqlServerName}${az.environment().suffixes.sqlServerHostname},1433;Initial Catalog=${accountingDbName};Persist Security Info=False;User ID=${sqlAdministratorLogin};Password=${sqlAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}
