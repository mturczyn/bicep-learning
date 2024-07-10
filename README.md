### Introducion

File contains notes about learning bicep.

**NOTE** some bicep and az commands should be interchangeable - commands/function found in bicep should have their counterpart in az command and vice versa.

### Basic information and initial notes

When defining a resource, we can use `existing` keyword to indicate existing resource, that we  want just reference in bicep scripts without creation.

When using `params`, params provided must match exactly required parameters in module/template.
Of course, there can be multiple values provided to params, in that case there's precedence that will determine which value to use.
But if you don't provide any value for any param, or we provide value for non-existing parameter, the bicep validation will fail.

### For loop and parallel deployment

Bicep also supports loops. When bicep runs loops it deploys resources in parallel. To limit that we can use `batchSize` decorator:
```
@batchSize(2)
resource storageAccounts 'Microsoft.Storage/storageAccounts@2023-05-01' = [for i in range(1, 3): {
  name: 'mtwebapp-${i}'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Cold'
  }
}]
```
Other usages of arrays:
```
var items = [for i in range(1,5): 'item${i}']
```

### Child resources

Sometimes, we need to define resources with children, such as SQL server and SQL database, or Storage Account together with some container. There are multiple ways to do that. See [example bicep file](./child-resources/main.bicep).  
Other ways to write the same:

- Alternative way to define child resource outside parent is to specify property `parent: sqlServer`, as below:
  ```
  resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
    name: sqlServerName
    location: location
    properties: {
      administratorLogin: sqlServerAdministratorLogin
      administratorLoginPassword: sqlServerAdministratorPassword
    }
  }

  resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
    parent: sqlServer
    name: sqlDatabaseName
    location: location
    sku: {
      name: sqlDatabaseSku.name
      tier: sqlDatabaseSku.tier
    }
  }
  ```
- yet another way is to specify parent resource in the string interpolation and add the symoblic name to `dependsOn`
  ```
  resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
    name: sqlServerName
    location: location
    properties: {
      administratorLogin: sqlServerAdministratorLogin
      administratorLoginPassword: sqlServerAdministratorPassword
    }
  }

  resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
    name: '${sqlServerName}/${sqlDatabaseName}'
    location: location
    sku: {
      name: sqlDatabaseSku.name
      tier: sqlDatabaseSku.tier
    }
    dependsOn: [
      sqlServer
    ]
  }
  ```

### Referring to existing resources

You can refer to exsiting resources. Not only in the same resource group, but also in the same subscription or even different subscription within Microsoft Entra tenant:
```
// Resource in different Resource Group
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  scope: resourceGroup('networking-rg')
  name: 'toy-design-vnet'
}

// Resource in different Subscription
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  scope: resourceGroup('A123b4567c-1234-1a2b-2b1a-1234abc12345', 'networking-rg')
  name: 'toy-design-vnet'
}
```

### Extension resources

In order to created extension resource, such as lock on CosmosDB (or any other resource), we would write:
```
resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2020-04-01' = {
  name: cosmosDBAccountName
  location: location
  properties: {
    // ...
  }
}
```
And then, to add lock to it we would use `scope` property defined as `scope: cosmosDBAccount`:
```
resource lockResource 'Microsoft.Authorization/locks@2016-09-01' = {
  scope: cosmosDBAccount
  name: 'DontDelete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents deletion of the toy data Cosmos DB account.'
  }
}
```
**Extension resources** change the way resource behaves, such as locks prevents deletions of the resource (any resource).

### Deployment modes

Bicep deploys resources in different modes. By default bicep uses *incremenetal* mode, which means that bicep only adds or updates resources, but does not delete resources not speicified in bicep.

**Complete mode** - that mode should be specified explicitly. In that mode resources that exist in Azure but that aren't specified in the template are deleted. [Some resource types are exempt.](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-complete-mode-deletion), and do not get deleted in that mode.

### Deployment scopes

Each resource is deployed to some scope. Defaut scope is resource group, but also resources can be scopes themselves, for example: lock is resource that has to be deployed in scope of some resource.

To define scope for the whole bicep file we need to specify `targetScope` to one of the values: `resourceGroup`, `subscription`, `managementGroup` or `tenant`. The information what to use exactly (what resource group or what subscription) is provided via command line parameters for AZ cmdlet. Bicep assumes `resourceGroup` by default.

Depending on scope at which we want to execute our bicep script, we use different Azure CLI command:
- `az deployment group create` to deploy to resource group
- `az deployment sub create` to deploy to subscription
- `az deployment mg create` to deploy to management group
- `az deployment tenant create` to deploy to tenant

In order to override scope set for entire bicep file, modules (and some Azure resources, like extension resources) support `scope` property, that can be used to deploy resource to different scope, for example:
```
targetScope = 'subscription'

module networkModule 'modules/network.bicep' = {
  scope: resourceGroup('ToyNetworking')
  name: 'networkModule'
}
```

### Template specs

A template spec is an Azure resource, just like a storage account or virtual machine. It must be created within a resource group, although the template itself can deploy resources to a subscription, management, or tenant scope.

In order to create template spec:
- create usual template (bicep or ARM)
- create template spec resource in Azure and deploy created template to that resource,

CLI to create template spec:
```
az ts create \
  --name StorageWithoutSAS \
  --lcoation westus \
  --dispaly-name "Storage account with SAS disabled" \
  --description "This template spec creates a storage account, which is preconfigured to disable SAS authentication."
  --version 1.0 \
  --template-file main.bicep
```
After successfully creating template spec in Azure, we can use it for our deployment, below is `az` command to deploy using template spec:
```
az deployment group create \
  --template-spec "/subscriptions/f0750bbe-ea75-4ae5-b24d-a92ca601da2c/resourceGroups/SharedTemplates/providers/Microsoft.Resources/templateSpecs/StorageWithoutSAS"
```
Of course, we can use template specs at various scopes, such as subscription or tenant.

We also can do usual stuff with template spec, just as with other resources:
- `az ts show` - show resource (if `--version` paramter is specified, output is for specific version of template spec)
- `as ts update` - update existing resource
- `az ts delete` - remove resource

Another thing to do is to export template of tepmlate spec:
```
az ts export \
  --resource-group MyResourceGroup \
  --name MyTemplateSpec
  --version 1.0 \
  --output-folder ./mytemplates
```

### Share bicep using container registry

We can store bicep files in Bicep registries.

To create Azure Container Registry:
```
az acr create \
  --name YOUR_CONTAINER_REGISTRY_NAME \
  --sku Basic \
  --location westus
```
To see content of registry:
```
az acr repository list --name YOUR_CONTAINER_REGISTRY_NAME
```
To publish module to registry:
```
az bicep publish --file module.bicep --target 'br:toycompany.azurecr.io/mymodules/modulename:moduleversion'
```
Where `br:toycompany.azurecr.io/mymodules/modulename:moduleversion` is module path in registry:
- `br` - scheme
- `toycompany.azurecr.io` - registry
- `mymodules/modulename` - module identifier
- `moduleversion` - tag

To use existing module from registry, we can use following bicep code:
```
module myModule 'br:myregistry.azurecr.io/modulepath/modulename:moduleversion' = {
  name: 'my-module'
  params: {
    moduleParameter1: 'value'
  }
}
```

### Key vault creation

How to create KV? in bicep_POC resource group i created KV, but i was not previliged enough to add secrets there.

> Because access to resource does not guarantee the access to what is inside (application like KV or DB - imagine not having db admin login and password, while DB requires authorization)