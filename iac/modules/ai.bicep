targetScope = 'resourceGroup'

@description('Deployment location.')
param location string

@description('AI Services tier.')
param aiServicesTier string

@description('AI Search service name.')
param searchName string

@description('AI Foundry (Cognitive Services) name.')
param aiName string

@description('Services VNet name.')
param vnetName string

@description('Private Endpoints subnet ID.')
param subnetPeId string

@description('Log Analytics Workspace resource ID.')
param lawId string

@description('Optional tags to apply.')
param tags object = {}

resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchName
  location: location
  tags: tags
  sku: {
    name: aiServicesTier
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    publicNetworkAccess: 'Disabled'
    hostingMode: 'default'
  }
}

resource ai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiName
  location: location
  kind: 'CognitiveServices'
  tags: tags
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource peSearch 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-${search.name}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetPeId
    }
    privateLinkServiceConnections: [
      {
        name: 'search-conn'
        properties: {
          groupIds: [
            'searchService'
          ]
          privateLinkServiceId: search.id
        }
      }
    ]
    privateDnsZoneGroups: [
      {
        name: 'search-dns'
        properties: {
          privateDnsZoneConfigs: [
            {
              name: 'privatelink.search.windows.net'
              properties: {
                privateDnsZoneId: subscriptionResourceId('Microsoft.Network/privateDnsZones', 'privatelink.search.windows.net')
              }
            }
          ]
        }
      }
    ]
  }
}

resource peAi 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-${ai.name}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetPeId
    }
    privateLinkServiceConnections: [
      {
        name: 'ai-conn'
        properties: {
          groupIds: [
            'account'
          ]
          privateLinkServiceId: ai.id
        }
      }
    ]
    privateDnsZoneGroups: [
      {
        name: 'ai-dns'
        properties: {
          privateDnsZoneConfigs: [
            {
              name: 'privatelink.cognitiveservices.azure.com'
              properties: {
                privateDnsZoneId: subscriptionResourceId('Microsoft.Network/privateDnsZones', 'privatelink.cognitiveservices.azure.com')
              }
            }
          ]
        }
      }
    ]
  }
}

output searchId string = search.id
output aiId string = ai.id

resource searchDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-law'
  scope: search
  properties: {
    workspaceId: lawId
    logs: [
      {
        category: 'AllMetrics'
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

resource aiDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-law'
  scope: ai
  properties: {
    workspaceId: lawId
    logs: [
      {
        category: 'AuditEvent'
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
@description('Optional tags to apply.')
param tags object = {}

// TODO: deploy AI Search and AI Foundry with private endpoints.
