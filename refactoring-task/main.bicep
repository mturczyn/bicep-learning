param location string = resourceGroup().location

@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
param appServicePlanSkuName string = 'F1'

@minValue(1)
param skuCapacity int = 1
param sqlAdministratorLogin string

@secure()
param sqlAdministratorLoginPassword string

param managedIdentityName string = uniqueString(resourceGroup().id)

@description('The role definition ID of the built-in Azure \'Contributor\' role.')
var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'

param appServiceAppName string = 'webSite${uniqueString(resourceGroup().id)}'
param container1Name string = 'productspecs'
param productmanualsName string = 'productmanuals'

@allowed(['NonProduction', 'Production'])
param environmentType string = 'NonProduction'

var appServicePlanName = 'hostingplan${uniqueString(resourceGroup().id)}'
var sqlserverName = 'toywebsite${uniqueString(resourceGroup().id)}'
var storageAccountName = 'toywebsite${uniqueString(resourceGroup().id)}'

var configSet = {
  Production: {
    appServicePlanSku: {
      name: 'S1'
      instanceCount: 2
    }
    storageAccountSku: 'GRS'
    sqlDbSku: 'S1'
  }
  NonProduction: {
    appServicePlanSku: {
      name: 'F1'
      instanceCount: 1
    }
    storageAccountSku: 'LRS'
    sqlDbSku: 'Basic'
  }
}

var containerNames = [container1Name, productmanualsName]
var databaseName = 'ToyCompanyWebsite'

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: 'eastus'
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }

  resource blobServices 'blobServices' existing = {
    name: 'default'
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [for containerName in containerNames: {
  parent: storageAccount::blobServices
  name: '${environmentType}${containerName}'
}]

resource sqlServer 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlserverName
  location: location
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqlServerNameAllowAllAzureIPs 'Microsoft.Sql/servers/firewallRules@2014-04-01' = {
  parent: sqlServer
  name: 'AllowAllAzureIPs'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource sqlserverNameDatabaseName 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: configSet[environmentType].sqlDbSku
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
    capacity: skuCapacity
  }
}

resource appServiceApp 'Microsoft.Web/sites@2020-06-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: AppInsightsWebSiteName.properties.InstrumentationKey
        }
        {
          name: 'StorageAccountConnectionString'
          value: storageAccountConnectionString
        }
      ]
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      // This format is required when working with user-assigned managed identities.
      '${managedIdenetity.id}': {}
    }
  }
}

resource managedIdenetity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

resource appServiceAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  // Create a GUID based on the role definition ID and scope (resource group ID). 
  // This will return the same GUID every time the template is deployed to the same
  // resource group.
  name: guid(contributorRoleDefinitionId, resourceGroup().id)

  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefinitionId)
    principalId: managedIdenetity.properties.principalId
  }
}

resource AppInsightsWebSiteName 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: 'AppInsights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
