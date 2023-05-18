@description('The managed identity id of the app service.')
param managedIdentityId string

@description('The name of the container registry.')
param container_registry_name string

//@description('The name of the container registry resource group.')
//param acr_resource_group_name string

@description('The role definition id for the acrpull role.')
param role_definition_id string

//existing acr
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: container_registry_name
}

// Create role definition from the guid
resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: role_definition_id
}

// Create role assignment, you will need write access on the subscription to add this role assignment which is above 
// the contributor role
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(resourceGroup().id, 'acrRoleAssignment'))
  scope: acr
  properties: {
    description: 'Assign AcrPull role to app service'
    principalId: managedIdentityId
    roleDefinitionId: roleDefinition.id
  }
}
