@secure()
param administratorLoginPassword string
@secure()
param administratorLogin string
@allowed(['prod', 'nonprod'])
param envName string

var auditingEnabled = envName == 'prod'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = if(auditingEnabled) {
  name: 'mtconditionalstorage'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier:'Cool'
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: 'mtconditionalsqlserver'
  location: resourceGroup().location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

resource sqlServerAudit 'Microsoft.Sql/servers/auditingSettings@2021-11-01-preview' = if (auditingEnabled) {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    storageEndpoint: auditingEnabled == 'Production' ? storageAccount.properties.primaryEndpoints.blob : ''
    storageAccountAccessKey: auditingEnabled == 'Production' ? storageAccount.listKeys().keys[0].value : ''
  }
}
