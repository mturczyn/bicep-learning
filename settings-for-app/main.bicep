var location = resourceGroup().location
var thisTestPrefix = 'settingpoc'
var srvFarmName = '${thisTestPrefix}srvfarm'
var webappName = '${thisTestPrefix}webapp'
// Example settings
var settings = {
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  WORKFLOWS_RESOURCE_GROUP_NAME: resourceGroup().name
  WORKFLOWS_SUBSCRIPTION_ID: subscription().subscriptionId
  BICEP_POC_TEST_SETTING: 'Michal is the best ever'
}

// resource someApp 'Microsoft.Web/sites@2022-09-01' existing =  {
//   name: functionName

//   resource config 'config@2022-09-01' = {
//     name: 'appsettings'
//     properties: union(currentAppSettings, appSettings)
//   }
// }
var michalTestTags = {
  purpose: 'pure michal test'
}

// resource config 'Microsoft.Web/sites/config@2022-09-01' = {
//   name: 'a/a'
// }

// resource appconfig 'Microsoft.Web/sites/config/appsettings@2022-09-01' existing = {
//   name: 'sa/d/f'
// }

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: srvFarmName
  location: location
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  tags: michalTestTags
  // NOT APPLICABLE TO THIS TYPE OF RESOURCE
  // resource config1 'config@2022-09-01' = {
  //   name: 'appsettings'
  //   properties: settings
  // }
}

resource appServiceApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webappName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
  tags: michalTestTags
  
  resource config2 'config@2022-09-01' = {
    name: 'appsettings'
    properties: settings
  }
}
