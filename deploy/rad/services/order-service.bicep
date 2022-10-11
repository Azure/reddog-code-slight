import radius as radius

param appId string
param environment string

param daprPubSubBrokerName string

var daprAppId = 'order-service'

resource daprPubSubBroker 'Applications.Connector/daprPubSubBrokers@2022-03-15-privatepreview' existing = {
  name: daprPubSubBrokerName
}

resource orderService 'Applications.Core/containers@2022-03-15-privatepreview' = {
  name: daprAppId
  location: 'global'
  properties: {
    application: appId
    container: {
      image: 'awkwardindustries.azurecr.io/reddog/order-service:r1'
    }
    extensions: [
      {
        kind: 'daprSidecar'
        appId: daprAppId
        appPort: 80
        provides: orderServiceDaprRoute.id
      }
    ]
    connections: {
      pubsub: {
        source: daprPubSubBroker.id
      }
    }
  }
}

resource orderServiceDaprRoute 'Applications.Connector/daprInvokeHttpRoutes@2022-03-15-privatepreview' = {
  name: '${daprAppId}-dapr-route'
  location: 'global'
  properties: {
    application: appId
    environment: environment
    appId: daprAppId
  }
}

output orderServiceDaprRouteName string = orderServiceDaprRoute.name
