targetScope = 'resourceGroup'

@description('Deployment location.')
param location string

@description('Log Analytics retention in days.')
param lawRetentionDays int

@description('Log Analytics Workspace name.')
param lawName string

@description('Optional tags to apply.')
param tags object = {}

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: lawRetentionDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Custom table required by PRD-30
resource customTable 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  name: '${law.name}/VibeData_Operations_CL'
  properties: {
    retentionInDays: 30
    totalRetentionInDays: 30
    schema: {
      name: 'VibeData_Operations_CL'
      columns: [
        {
          name: 'Message'
          type: 'string'
        }
        {
          name: 'Severity'
          type: 'string'
        }
        {
          name: 'Timestamp'
          type: 'datetime'
        }
      ]
    }
  }
}

output lawId string = law.id

// TODO: deploy Log Analytics Workspace, custom table, and diagnostic settings.
