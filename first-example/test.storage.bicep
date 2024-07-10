resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: 'a1f1a3b62c7bfe0st'
  location: 'North Europe'
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

// second example with returning resource ID
// param location string = resourceGroup().location
// param namePrefix string = 'storage'

// var storageAccountName = '${namePrefix}${uniqueString(resourceGroup().id)}'
// var storageAccountSku = 'Standard_RAGRS'

// resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
//   name: storageAccountName
//   location: location
//   kind: 'StorageV2'
//   sku: {
//     name: storageAccountSku
//   }
//   properties: {
//     accessTier: 'Hot'
//     supportsHttpsTrafficOnly: true
//   }
// }

// output storageAccountId string = storageAccount.id
