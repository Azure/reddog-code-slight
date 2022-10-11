import radius as radius

param appId string
param environment string

param daprPubSubBrokerName string
param daprStateStoreName string

var daprAppId = 'make-line-service'

resource daprPubSubBroker 'Applications.Connector/daprPubSubBrokers@2022-03-15-privatepreview' existing = {
  name: daprPubSubBrokerName
}

resource daprStateStore 'Applications.Connector/daprStateStores@2022-03-15-privatepreview' existing = {
  name: daprStateStoreName
}

resource makelineService 'Applications.Core/containers@2022-03-15-privatepreview' = {
  name: daprAppId
  location: 'global'
  properties: {
    application: appId
    container: {
      image: 'awkwardindustries.azurecr.io/reddog/make-line-service:r1'
    }
    extensions: [
      {
        kind: 'daprSidecar'
        appId: daprAppId
        appPort: 80
        provides: makelineServiceDaprRoute.id
      }
    ]
    connections: {
      statestore: {
        source: daprStateStore.id
      }
      pubsub: {
        source: daprPubSubBroker.id
      }
    }
  }
}

resource makelineServiceDaprRoute 'Applications.Connector/daprInvokeHttpRoutes@2022-03-15-privatepreview' = {
  name: '${daprAppId}-dapr-route'
  location: 'global'
  properties: {
    application: appId
    environment: environment
    appId: daprAppId
  }
}

output makelineServiceDaprRouteName string = makelineServiceDaprRoute.name
