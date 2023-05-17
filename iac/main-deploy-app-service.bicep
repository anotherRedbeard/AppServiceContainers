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

@description('The name of the container registry resource group.')
param acr_resource_group_name string

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

// Create role assignment
module acrPullRoleAssignment './role-assignment.bicep' = {
  name: 'AcrPullRoleAssignment'
  scope: resourceGroup(acr_resource_group_name)
  params: {
    managedIdentityId: appService.outputs.managedIdentityId
    container_registry_name: container_registry_name
    //acr_resource_group_name: acr_resource_group_name
    //pulled from https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
    role_definition_id: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  }
}

output appServiceName string = appService.outputs.appName
output appServicePlanName string = appService.outputs.aspName
output appServiceManagedIdentityName string = appService.outputs.managedIdentityId
