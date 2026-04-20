param hub_vnet_externalid string
param hub_vnet_resolver_subnet string
param private_dns_resolver_name string
param private_dns_resolver_inbound_endpoint_name string
param hub_vnet_location string

param zones array = [
  'privatelink.api.azureml.ms'
  'privatelink.notebooks.azure.net'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.openai.azure.com'
  'privatelink.services.ai.azure.com'
  'privatelink.directline.botframework.com'
  'privatelink.token.botframework.com'
  'privatelink.sql.azuresynapse.net'
  'privatelink.dev.azuresynapse.net'
  'privatelink.azuresynapse.net'
  'privatelink.servicebus.windows.net'
  'privatelink.datafactory.azure.net'
  'privatelink.adf.azure.com'
  'privatelink.azurehdinsight.net'
  'privatelink.blob.core.windows.net'
  'privatelink.queue.core.windows.net'
  'privatelink.table.core.windows.net'
  'privatelink.analysis.windows.net'
  'privatelink.pbidedicated.windows.net'
  'privatelink.prod.powerquery.microsoft.com'
  'privatelink.azuredatabricks.net'
  'privatelink.fabric.microsoft.com'
  'privatelink.batch.azure.com'
  'privatelink-global.wvd.microsoft.com'
  'privatelink.wvd.microsoft.com'
  'privatelink.azurecr.io'
  'privatelink.database.windows.net'
  'privatelink.documents.azure.com'
  'privatelink.mongo.cosmos.azure.com'
  'privatelink.cassandra.cosmos.azure.com'
  'privatelink.gremlin.cosmos.azure.com'
  'privatelink.table.cosmos.azure.com'
  'privatelink.analytics.cosmos.azure.com'
  'privatelink.postgres.cosmos.azure.com'
  'privatelink.mongocluster.cosmos.azure.com'
  'privatelink.postgres.database.azure.com'
  'privatelink.mysql.database.azure.com'
  'privatelink.mariadb.database.azure.com'
  'privatelink.redis.cache.windows.net'
  'privatelink.redisenterprise.cache.azure.net'
  'privatelink.redis.azure.net'
  'privatelink.his.arc.azure.com'
  'privatelink.guestconfiguration.azure.com'
  'privatelink.dp.kubernetesconfiguration.azure.com'
  'privatelink.eventgrid.azure.net'
  'privatelink.ts.eventgrid.azure.net'
  'privatelink.azure-api.net'
  'privatelink.azurehealthcareapis.com'
  'privatelink.dicom.azurehealthcareapis.com'
  'privatelink.azure-devices.net'
  'privatelink.azure-devices-provisioning.net'
  'privatelink.api.adu.microsoft.com'
  'privatelink.azureiotcentral.com'
  'privatelink.digitaltwins.azure.net'
  'privatelink.media.azure.net'
  'privatelink.azure-automation.net'
  'privatelink.siterecovery.windowsazure.com'
  'privatelink.monitor.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.ods.opinsights.azure.com'
  'privatelink.agentsvc.azure-automation.net'
  'privatelink.purview.azure.com'
  'privatelink.purviewstudio.azure.com'
  'privatelink.purview-service.microsoft.com'
  'privatelink.prod.migration.windowsazure.com'
  'privatelink.azure.com'
  'privatelink.grafana.azure.com'
  'privatelink.vaultcore.azure.net'
  'privatelink.managedhsm.azure.net'
  'privatelink.azconfig.io'
  'privatelink.attest.azure.net'
  'privatelink.file.core.windows.net'
  'privatelink.web.core.windows.net'
  'privatelink.dfs.core.windows.net'
  'privatelink.afs.azure.net'
  'privatelink.search.windows.net'
  'privatelink.azurewebsites.net'
  'scm.privatelink.azurewebsites.net'
  'privatelink.service.signalr.net'
  'privatelink.azurestaticapps.net'
  'privatelink.webpubsub.azure.com'
]

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2024-06-01' = [
  for zone in zones: {
    name: zone
    location: 'global'
    properties: {}
  }
]

resource privateDnsZones_links 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for (zone, i) in zones: {
    parent: privateDnsZones[i]
    name: 'hub'
    location: 'global'
    properties: {
      registrationEnabled: false
      resolutionPolicy: 'Default'
      virtualNetwork: {
        id: hub_vnet_externalid
      }
    }
  }
]

resource dnsResolvers 'Microsoft.Network/dnsResolvers@2025-10-01-preview' = {
  name: private_dns_resolver_name
  location: hub_vnet_location
  properties: {
    virtualNetwork: {
      id: hub_vnet_externalid
    }
  }
}

resource dnsResolvers_inboundEndpoints 'Microsoft.Network/dnsResolvers/inboundEndpoints@2025-10-01-preview' = {
  parent: dnsResolvers
  name: private_dns_resolver_inbound_endpoint_name
  location: hub_vnet_location
  properties: {
    ipConfigurations: [
      {
        subnet: {
          id: '${hub_vnet_externalid}/subnets/${hub_vnet_resolver_subnet}'
        }
        privateIpAllocationMethod: 'Dynamic'
      }
    ]
  }
}
