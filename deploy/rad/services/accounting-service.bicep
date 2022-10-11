import radius as radius

param appId string
param environment string

param daprPubSubBrokerName string
@secure()
param sqlConnectionString string

var daprAppId = 'accounting-service'

resource daprPubSubBroker 'Applications.Connector/daprPubSubBrokers@2022-03-15-privatepreview' existing = {
  name: daprPubSubBrokerName
}

resource accountingService 'Applications.Core/containers@2022-03-15-privatepreview' = {
  name: daprAppId
  location: 'global'
  properties: {
    application: appId
    container: {
      image: 'awkwardindustries.azurecr.io/reddog/accounting-service:r1'
      env: {
        'reddog-sql': sqlConnectionString
      }
      readinessProbe: {
        kind: 'httpGet'
        containerPort: 80
        path: '/probes/ready'
        failureThreshold: 10
        periodSeconds: 10
      }
      livenessProbe: {
        kind: 'httpGet'
        containerPort: 80
        path: '/probes/healthz'
        failureThreshold: 6
        periodSeconds: 10
      }
    }
    extensions: [
      {
        kind: 'daprSidecar'
        appId: daprAppId
        appPort: 80
        provides: accountingServiceDaprRoute.id
      }
    ]
    connections: {
      pubsub: {
        source: daprPubSubBroker.id
      }
    }
  }
}

resource accountingServiceDaprRoute 'Applications.Connector/daprInvokeHttpRoutes@2022-03-15-privatepreview' = {
  name: '${daprAppId}-dapr-route'
  location: 'global'
  properties: {
    application: appId
    environment: environment
    appId: daprAppId
  }
}

output accountingServiceDaprRouteName string = accountingServiceDaprRoute.name
