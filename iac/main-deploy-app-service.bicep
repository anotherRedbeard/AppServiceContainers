// =========== main.bicep ===========
@minLength(1)
@description('The location of the app service')
param location string = resourceGroup().location

@maxLength(10)
@minLength(2)
@description('The name of the app service to create.')
param app_service_postfix string 

@allowed([
  'B1'
])
@description('The name of the app service sku.')
param app_service_sku string

@description('The name of the deployment for the app service.')
param app_service_deployment_name string = 'AppServiceDeployment'

@description('The name of the container image to deploy.')
param app_container_image_name string = 'mcr.microsoft.com/azuredocs/aci-helloworld'

@description('The name of the container registry.')
param container_registry_name string

// =================================

// Create Log Analytics workspace
module logws './log-analytics-ws.bicep' = {
  name: 'LogWorkspaceDeployment'
  params: {
    name: app_service_postfix
    location: location
  }
}

// Create app service
module appService './app-service.bicep' = {
  name: app_service_deployment_name
  params: {
    webAppName: app_service_postfix
    sku: app_service_sku
    appServicePlanKind: 'Linux,Container'
    location: location
    logwsid: logws.outputs.id
    linuxFxVersion: 'DOCKER|${app_container_image_name}'
  }
}

//existing acr
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: container_registry_name
}

// Create role assignment, you will need write access on the subscription to add this role assignment which is above 
// the contributor role
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(resourceGroup().id, 'acrRoleAssignment'))
  scope: acr
  properties: {
    description: 'Assign AcrPull role to app service'
    principalId: appService.outputs.managedIdentityId
    //pulled from https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  }
}

output appServiceName string = appService.outputs.appName
output appServicePlanName string = appService.outputs.aspName
output appServiceManagedIdentityName string = appService.outputs.managedIdentityId
