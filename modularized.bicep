@maxLength(10)
param michalTestPrefix string = 'michaltest'
@allowed(['nonprod','prod'])
param envType string
param appServicePlanSku object
@secure()
@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string
@secure()
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorPassword string
@description('The name and tier of the SQL database SKU.')
param sqlDatabaseSku object

module myModule 'main.bicep' = {
  name: 'MyModule'
  params: {
    envType: envType
    michalTestPrefix: michalTestPrefix
    michalTestTags: {
      environmentName: 'bicepPOC'
      team: 'Hydra Michal'
    }
    appServicePlanSku: appServicePlanSku
  }
}

module sqlDb 'database.bicep' = {
  name: 'SqlDb'
  params: {
    sqlDatabaseSku: sqlDatabaseSku
    sqlServerAdministratorLogin: sqlServerAdministratorLogin
    sqlServerAdministratorPassword: sqlServerAdministratorPassword
  }
}

output appServiceAppHostName string = myModule.outputs.appServiceAppHostName
