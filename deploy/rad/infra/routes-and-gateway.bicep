import radius as radius

param appId string

resource uiRoute 'Applications.Core/httpRoutes@2022-03-15-privatepreview' = {
  name: 'ui-route'
  location: 'global'
  properties: {
    application: appId
  }
}

resource gateway 'Applications.Core/gateways@2022-03-15-privatepreview' = {
  name: 'gateway'
  location: 'global'
  properties: {
    application: appId
    routes: [
      {
        path: '/'
        destination: uiRoute.id
      }
    ]
  }
}

output uiRouteName string = uiRoute.name
output url string = gateway.properties.url
