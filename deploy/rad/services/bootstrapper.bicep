import radius as radius

param appId string

@secure()
param sqlConnectionString string

resource bootstrapper 'Applications.Core/containers@2022-03-15-privatepreview' = {
  name: 'bootstrapper'
  location: 'global'
  properties: {
    application: appId
    container: {
      image: 'awkwardindustries.azurecr.io/reddog/bootstrapper:r1'
      env: {
        'reddog-sql': sqlConnectionString
      }
      
    }
  }
}
