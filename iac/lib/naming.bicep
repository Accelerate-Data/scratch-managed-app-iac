@description('Resource group name used as seed for deterministic nanoid generation.')
param resourceGroupName string

@description('Logical purpose string to include in names (e.g., platform).')
param purpose string = 'platform'

// helper to build deterministic nanoids per resource type
param seedPrefix string = resourceGroupName

var nano16 = (suffix) => toLower('${substring(uniqueString('${seedPrefix}-${suffix}-a'), 0, 8)}${substring(uniqueString('${seedPrefix}-${suffix}-b'), 0, 8)}')
var nano8 = (suffix) => toLower(substring(uniqueString('${seedPrefix}-${suffix}-st'), 0, 8))

var names = {
  uami: 'vd-uami-${purpose}-${nano16('uami')}'
  vnet: 'vd-vnet-${purpose}-${nano16('vnet')}'
  nsgAppgw: 'vd-nsg-appgw-${nano16('nsgappgw')}'
  nsgAks: 'vd-nsg-aks-${nano16('nsgaks')}'
  nsgAppsvc: 'vd-nsg-appsvc-${nano16('nsgappsvc')}'
  nsgPe: 'vd-nsg-pe-${nano16('nsgpe')}'
  kv: 'vd-kv-${purpose}-${nano16('kv')}'
  storage: 'vdst${purpose}${nano8('st')}'
  acr: 'vd-acr-${purpose}-${nano16('acr')}'
  law: 'vd-law-${purpose}-${nano16('law')}'
  asp: 'vd-asp-${purpose}-${nano16('asp')}'
  appApi: 'vd-app-api-${nano16('appapi')}'
  appUi: 'vd-app-ui-${nano16('appui')}'
  funcOps: 'vd-func-ops-${nano16('func')}'
  agw: 'vd-agw-${purpose}-${nano16('agw')}'
  pipAgw: 'vd-pip-agw-${nano16('pipagw')}'
  psql: 'vd-psql-${purpose}-${nano16('psql')}'
  search: 'vd-search-${purpose}-${nano16('search')}'
  ai: 'vd-ai-${purpose}-${nano16('ai')}'
  automation: 'vd-aa-${purpose}-${nano16('aa')}'
}

output names object = names
