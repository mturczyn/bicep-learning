param michalTestPrefix string = 'michaltest'
@allowed(['nonprod','prod'])
param envType string
param michalTestTags object
param appServicePlanSku object

var storageSku = envType == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
var resourceGroupLocation = resourceGroup().location
var rgId = resourceGroup().id
var storageName = '${michalTestPrefix}${uniqueString(rgId)}st'
var serverFarmName = '${michalTestPrefix}${uniqueString(rgId)}farm'
var webappName = '${michalTestPrefix}${uniqueString(rgId)}webapp'
var createAnoterStorage = envType == 'prod'

resource additionalSorage 'Microsoft.Storage/storageAccounts@2022-09-01' = if(createAnoterStorage) {
  name: take('${michalTestPrefix}additionalst', 24)
  location: resourceGroupLocation
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
  tags: michalTestTags
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: resourceGroupLocation
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
  tags: michalTestTags
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: serverFarmName
  location: resourceGroupLocation
  sku: appServicePlanSku
  tags: michalTestTags
}

resource appServiceApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webappName
  location: resourceGroupLocation
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
  tags: michalTestTags
}

output appServiceAppHostName string = appServiceApp.properties.defaultHostName
