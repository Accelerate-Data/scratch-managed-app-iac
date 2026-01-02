targetScope = 'resourceGroup'

@description('Deployment location.')
param location string

@description('PostgreSQL compute tier SKU.')
param postgresComputeTier string

@description('PostgreSQL server name.')
param psqlName string

@description('Services VNet name (for private endpoint).')
param vnetName string

@description('Private Endpoints subnet ID.')
param subnetPeId string

@description('Principal ID of the UAMI for RBAC.')
param uamiPrincipalId string

@description('Log Analytics Workspace resource ID.')
param lawId string
@description('Optional tags to apply.')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource psql 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: psqlName
  location: location
  tags: tags
  sku: {
    name: postgresComputeTier
    tier: 'GeneralPurpose'
  }
  properties: {
    administratorLogin: null
    administratorLoginPassword: null
    version: '16'
    storage: {
      storageSizeGB: 128
      autoGrow: 'Enabled'
      iops: 0
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: subscription().tenantId
    }
    highAvailability: {
      mode: 'Disabled'
    }
    createMode: 'Default'
  }
}

resource pePsql 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-${psql.name}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetPeId
    }
    privateLinkServiceConnections: [
      {
        name: 'psql-conn'
        properties: {
          groupIds: [
            'postgresqlServer'
          ]
          privateLinkServiceId: psql.id
        }
      }
    ]
    privateDnsZoneGroups: [
      {
        name: 'psql-dns'
        properties: {
          privateDnsZoneConfigs: [
            {
              name: 'privatelink.postgres.database.azure.com'
              properties: {
                privateDnsZoneId: subscriptionResourceId('Microsoft.Network/privateDnsZones', 'privatelink.postgres.database.azure.com')
              }
            }
          ]
        }
      }
    ]
  }
}

resource psqlAdminRole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(psql.id, uamiPrincipalId, 'psql-admin')
  scope: psql
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1f21df41-19d2-41e1-8a5e-3cbb7a0c2bd2') // PostgreSQL Flexible Server Administrator
    principalId: uamiPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output psqlId string = psql.id

resource psqlDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-law'
  scope: psql
  properties: {
    workspaceId: lawId
    logs: [
      {
        category: 'PostgreSQLLogs'
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

// TODO: deploy PostgreSQL Flexible Server v16 with roles per PRD-30.
