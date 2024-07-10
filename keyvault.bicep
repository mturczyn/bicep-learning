@description('Object ID of user/other resource in Azure that will ahve access to key vault.')
param objectIdForKeyVaultAccess string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'mttestkeyvault'
  location: 'northeurope'
  tags: {
    tagName1: 'test only'
  }
  properties: {
    enabledForTemplateDeployment: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: [
      {
        // optional
        // applicationId: 'string'
        objectId: objectIdForKeyVaultAccess
        permissions: {
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
        tenantId: tenant().tenantId
      }
    ]
    // createMode: 'string'
    // enabledForDeployment: bool
    // enabledForDiskEncryption: bool
    // enablePurgeProtection: bool
    // enableRbacAuthorization: bool
    // enableSoftDelete: bool
    // networkAcls: {
    //   bypass: 'string'
    //   defaultAction: 'string'
    //   ipRules: [
    //     {
    //       value: 'string'
    //     }
    //   ]
    //   virtualNetworkRules: [
    //     {
    //       id: 'string'
    //       ignoreMissingVnetServiceEndpoint: bool
    //     }
    //   ]
    // }
    // provisioningState: 'string'
    // publicNetworkAccess: 'string'
    // softDeleteRetentionInDays: int
    // vaultUri: 'string'
  }
}
