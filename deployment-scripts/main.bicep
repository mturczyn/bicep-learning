resource myFirstDeploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'myFirstDeployment'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/01234567-89AB-CDEF-0123-456789ABCDEF/resourcegroups/deploymenttest/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myscriptingid': {}
    }
  }
  properties: {
    // Way to use script parameters.
    arguments: '-Name Learner'
    // Environment variables
    environmentVariables: [
      {
        name: 'Subject'
        value: 'Deployment Scripts'
      }
      {
        name: 'MySecret'
        secureValue: 'DoNotPrintMeToConsole'
      }
    ]
    azPowerShellVersion: '3.0'
    retentionInterval: 'P1D'
    scriptContent: '''
      param ([string]$Name)
      $output = 'Hello $Name!!'
      $output += " Learning about $env:Subject can be very helpful."
      $output += "Secure environment variables (like $env:MySecretValue) are only secure if you keep them that way."
      Write-Output $output
      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs['text'] = $output
    '''
  }
}

resource includeOtherPowerShell 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'includeOtherPowerShellDeployment'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/01234567-89AB-CDEF-0123-456789ABCDEF/resourcegroups/deploymenttest/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myscriptingid': {}
    }
  }
  properties: {
    azPowerShellVersion: '3.0'
    retentionInterval: 'P1D'
    // Include other PowerShell script.
    scriptContent: loadTextContent('somescript.ps1')
  }
}

// resource commandLineArgumentExample 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
//   name: 'commandLineArgumentExampleDeployment'
//   location: resourceGroup().location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '/subscriptions/01234567-89AB-CDEF-0123-456789ABCDEF/resourcegroups/deploymenttest/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myscriptingid': {}
//     }
//   }
//   properties: {
//     azPowerShellVersion: '3.0'
//     retentionInterval: 'P1D'

//   }
// }
