@description('The managed identity id of the app service.')
param managedIdentityId string

@description('The name of the container registry.')
param container_registry_name string

@description('The role definition id for the acrpull role.')
param role_definition_id string

@description('The role assignment name')
param role_assignment_name string

@description('The role assignment description')
param role_assignment_desc string

//existing acr
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: container_registry_name
}

// Get role definition from the guid
resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: role_definition_id
}

// Create role assignment, you will need write access on the subscription to add this role assignment which is above 
// the contributor role
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(resourceGroup().id, managedIdentityId, role_assignment_name))
  scope: acr
  properties: {
    description: role_assignment_desc
    principalId: managedIdentityId
    roleDefinitionId: roleDefinition.id
  }
}
