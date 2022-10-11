import radius as radius

param appId string
param environment string
param location string
param uniqueSeed string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: 'sb-${uniqueString(uniqueSeed)}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource daprPubSubBroker 'Applications.Connector/daprPubSubBrokers@2022-03-15-privatepreview' = {
  name: 'pubsub'
  location: 'global'
  properties: {
    application: appId
    environment: environment
    kind: 'pubsub.azure.servicebus'
    resource: serviceBus.id
  }
}

output daprPubSubBrokerName string = daprPubSubBroker.name
