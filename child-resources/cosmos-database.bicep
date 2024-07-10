param cosmosDBAccountName string = 'mt-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param cosmosDBDatabaseThroughput int = 400
param storageAccountName string

var cosmosDBDatabaseName = 'mt-FlightTests'
var cosmosDBContainerName = 'mt-FlightTests'
var cosmosDBContainerPartitionKey = '/droneId'

// AZ command used to create log analytics.
// az monitor log-analytics workspace create --workspace-name mt-test-logs --location northeurope --resource-group  Bicep_PoC_TestArea
var logAnalyticsWorkspaceName = 'mt-test-logs'
var cosmosDBAccountDiagnosticSettingsName = 'route-logs-to-log-analytics'

// AZ command used to create storage account for documents.
// az storage account create --name mtexttestst --location northeurope --resource-group Bicep_PoC_TestArea
var storageAccountBlobDiagnosticSettingsName = 'route-logs-to-log-analytics'

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosDBAccountName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      { locationName:location }
    ]
  }
}

resource comosDBDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosDBAccount
  name: cosmosDBDatabaseName
  properties: {
    resource: { id: cosmosDBDatabaseName }
    options: { throughput: cosmosDBDatabaseThroughput }
  }

  resource container 'containers' = {
    name: cosmosDBContainerName
    properties: {
      resource: {
        id: cosmosDBContainerName
        partitionKey: {
          kind: 'Hash'
          paths: [
            cosmosDBContainerPartitionKey
          ]
        }
      }
      options: {}
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource cosmosDBAccountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: cosmosDBAccount
  name: cosmosDBAccountDiagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName

  resource blobService 'blobServices' existing = {
    name: 'default'
  }
}

resource storageAccountBlobDiagnostics 'microsoft.aadiam/diagnosticSettings@2017-04-01-preview' = {
  scope: tenant() // storageAccount::blobService
  name: storageAccountBlobDiagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AuditLogs'
        enabled: true
      }
      {
        category: 'SignInLogs'
        enabled: true
      }
    ]
  }
}
