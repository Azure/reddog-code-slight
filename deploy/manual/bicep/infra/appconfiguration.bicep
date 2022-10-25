param configStoreName string
param location string

resource configStore 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = {
  name: configStoreName
  location: location
  sku: {
    name: 'standard'
  }
}
