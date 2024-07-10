// database.parameters.json file would suffice here.
// More notes in README file.

@secure()
@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string
@secure()
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorPassword string
@description('The name and tier of the SQL database SKU.')
param sqlDatabaseSku object

var location = resourceGroup().location
var sqlServerName = 'mt-sql-server'
var sqlDatabaseName = 'mt-database'

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorPassword
  }

  resource sqlDatabase 'databases' = {
    name: sqlDatabaseName
    location: location
    sku: {
      name: sqlDatabaseSku.name
      tier: sqlDatabaseSku.tier
    }
  }
}
