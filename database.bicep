@secure()
@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string
@secure()
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorPassword string
@description('The name and tier of the SQL database SKU.')
param sqlDatabaseSku object

var location = resourceGroup().location
var sqlServerName = 'mtsqlserver${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = 'mtdatabase${uniqueString(resourceGroup().id)}'

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorPassword
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: sqlDatabaseSku.name
    tier: sqlDatabaseSku.tier
  }
}
