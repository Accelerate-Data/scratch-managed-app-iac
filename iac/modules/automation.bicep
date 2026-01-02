targetScope = 'resourceGroup'

@description('Deployment location.')
param location string

@description('Automation Account name.')
param automationName string

@description('User-assigned managed identity resource id.')
param uamiId string

@description('Admin Object ID for customer (for Automation role).')
param adminObjectId string

@description('Log Analytics Workspace resource ID.')
param lawId string

@description('Optional tags to apply.')
param tags object = {}

resource automation 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
  sku: {
    name: 'Basic'
  }
}

output automationId string = automation.id

resource automationDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-law'
  scope: automation
  properties: {
    workspaceId: lawId
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Automation Job Operator for adminObjectId
resource adminAutomationJobOperator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(automation.id, adminObjectId, 'automation-job-operator')
  scope: automation
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4fe576fe-1146-4730-92eb-48519fa6bf9f')
    principalId: adminObjectId
    principalType: 'ServicePrincipal'
  }
}

// TODO: deploy Automation Account with UAMI and disable local auth.
