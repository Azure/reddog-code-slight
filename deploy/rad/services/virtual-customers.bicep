import radius as radius

param appId string
param environment string

param orderServiceDaprRouteName string

var daprAppId = 'virtual-customers'

resource orderServiceDaprRoute 'Applications.Connector/daprInvokeHttpRoutes@2022-03-15-privatepreview' existing = {
  name: orderServiceDaprRouteName
}

resource virtualCustomers 'Applications.Core/containers@2022-03-15-privatepreview' = {
  name: daprAppId
  location: 'global'
  properties: {
    application: appId
    container: {
      image: 'awkwardindustries.azurecr.io/reddog/virtual-customers:r1'
    }
    extensions: [
      {
        kind: 'daprSidecar'
        appId: daprAppId
        appPort: 80
        provides: virtualCustomersDaprRoute.id
      }
    ]
    connections: {
      orderservice: {
        source: orderServiceDaprRoute.id
      }
    }
  }
}

resource virtualCustomersDaprRoute 'Applications.Connector/daprInvokeHttpRoutes@2022-03-15-privatepreview' = {
  name: '${daprAppId}-dapr-route'
  location: 'global'
  properties: {
    application: appId
    environment: environment
    appId: daprAppId
  }
}

output virtualCustomersDaprRouteName string = virtualCustomersDaprRoute.name
