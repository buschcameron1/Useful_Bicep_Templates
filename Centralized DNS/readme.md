# Centralized DNS — Private DNS Zones & Resolver

## Overview

This template deploys centralized private DNS resolution for Azure infrastructure. It creates private DNS zones for all commercially available Azure Private Link domains, links them to a hub vNET, and creates a Private DNS Resolver with an inbound endpoint to allow spoke and on-premises networks to resolve private zone records.

Deploying the zones in advance lets non-IT staff create DNS records during resource provisioning without needing permission to create Private DNS Zone resources (they only need to update an existing zone). This is achieved by assigning the relevant security group **Private DNS Zone Contributor** rights over the resource group that houses the zones.

> **Recommendation:** Place the DNS zones in a dedicated resource group. They are global resources and do not need to share a resource group with the linked vNET.

> [!WARNING]
> This template deploys a **Private DNS Resolver** with an inbound endpoint. This is a billable resource and costs will be incurred for as long as it remains deployed. Review [Azure Private DNS Resolver pricing](https://azure.microsoft.com/en-in/pricing/details/dns) before deploying.

---

## Prerequisites

- Azure PowerShell module installed
- Contributor or equivalent rights over the target resource group
- A hub vNET with either a dedicated subnet for the DNS resolver inbound endpoint or a subnet between a /24 and /28 where the endpoint can be placed

---

## Deployment

Deploy using `New-AzResourceGroupDeployment`, supplying an existing resource group and the template file:

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "<your-resource-group>" `
  -TemplateFile "dns_zones_and_resolver.bicep"
```

---

## Parameters

| Parameter                                    | Description                                                                                                   |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `hub_vnet_externalid`                        | Resource ID of the hub vNET. See [Getting the hub vNET Resource ID](#getting-the-hub-vnet-resource-id) below. |
| `hub_vnet_resolver_subnet`                   | Resource ID of the subnet to host the resolver inbound endpoint.                                              |
| `private_dns_resolver_name`                  | Name for the Private DNS Resolver. Follow your environment's naming policy.                                   |
| `private_dns_resolver_inbound_endpoint_name` | Name for the inbound endpoint. This is an endpoint entry under the resolver, not a standalone resource.       |
| `hub_vnet_location`                          | Location (region) of the Hub vNET where the inbound endpoint will be placed.                                  |

> **Important:** The `hub_vnet_location` value must use the programmatic name (e.g., `canadacentral`, `eastus`, `westeurope`), not the display name shown in the Portal (e.g., "Canada Central"). For a mapping of Portal names to region codes, see [Azure regions](https://learn.microsoft.com/en-us/azure/reliability/regions-list?tabs=all#azure-regions-list-1).

### Inbound Endpoint Subnet Requirements

The subnet used for the resolver inbound endpoint must:

- Be between `/28` and `/24` in size
- Be reachable by all relevant spoke networks

Consider creating a dedicated subnet if address space allows

---

## Getting the hub vNET Resource ID

1. Open the hub vNET in the Azure Portal and click **JSON View** in the top-right corner.

   ![JSON View](JSON%20View.png)

2. Copy the **Resource ID** from the JSON View panel.

   ![Copy Resource ID](Copy%20Resource%20ID.png)

---

## Post-Deployment Steps

After the zones and resolver are deployed, complete the following:

1. **On-premises:** Create conditional forwarding rules that forward the relevant `privatelink.*` zones to the inbound endpoint IP of the Private DNS Resolver.
2. **Spoke vNETs:** Configure each spoke vNET to use the resolver inbound endpoint IP as its DNS server.

---

## DNS Resolution Architecture

The diagram below shows the flow DNS traffic takes to return private zone records. What makes Azure DNS function differently from standard DNS services is that the origin vnet of the request matters, this is what trips most teams up when deploying. The Azure DNS public server needs to recieve the DNS resolution request from a machine that sits on a vnet with the zones linked. A private resolver (in its most simple form) simply takes inbound DNS requests and forwards them so they appear to come from the vnet where the inbound endpoint sits.

![DNS Resolution Architecture](DNS%20Resolution.jpg)
