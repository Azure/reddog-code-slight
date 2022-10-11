import radius as radius

param appId string

param daprPubSubBrokerName string
param uiRouteName string
param makelineServiceDaprRouteName string
param accountingServiceDaprRouteName string

var daprAppId = 'ui'

resource daprPubSubBroker 'Applications.Connector/daprPubSubBrokers@2022-03-15-privatepreview' existing = {
  name: daprPubSubBrokerName
}

resource uiRoute 'Applications.Core/httproutes@2022-03-15-privatepreview' existing = {
  name: uiRouteName
}

resource makelineServiceDaprRoute 'Applications.Connector/daprInvokeHttpRoutes@2022-03-15-privatepreview' existing = {
  name: makelineServiceDaprRouteName
}

resource accountingServiceDaprRoute 'Applications.Connector/daprInvokeHttpRoutes@2022-03-15-privatepreview' existing = {
  name: accountingServiceDaprRouteName
}

resource ui 'Applications.Core/containers@2022-03-15-privatepreview' = {
  name: 'ui'
  location: 'global'
  properties: {
    application: appId
    container: {
      image: 'awkwardindustries.azurecr.io/reddog/ui:r1'
      ports: {
        web: {
          containerPort: 8080
          provides: uiRoute.id
        }
      }
      env: {
        VUE_APP_IS_CORP: 'false'
        VUE_APP_STORE_ID: 'Redmond'
        VUE_APP_SITE_TYPE: 'Pharmacy'
        VUE_APP_SITE_TITLE: 'Red Dog Bodega :: Market fresh food, pharmaceuticals, and fireworks!'
        VUE_APP_MAKELINE_BASE_URL: 'http://localhost:3500/v1.0/invoke/$(CONNECTION_MAKELINESERVICE_APPID)/method'
        VUE_APP_ACCOUNTING_BASE_URL: 'http://localhost:3500/v1.0/invoke/$(CONNECTION_ACCOUNTINGSERVICE_APPID)/method'
      }
    }
    extensions: [
      {
        kind: 'daprSidecar'
        appId: daprAppId
        appPort: 8080
      }
    ]
    connections: {
      pubsub: {
        source: daprPubSubBroker.id
      }
      makelineservice: {
        source: makelineServiceDaprRoute.id
      }
      accountingservice: {
        source: accountingServiceDaprRoute.id
      }
    }
  }
}
