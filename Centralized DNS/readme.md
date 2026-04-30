# Centralized DNS

## Overview

This folder contains the infrastructure template for a centralized Azure private DNS design.

The main template in [dns_zones_and_resolver.bicep](./dns_zones_and_resolver.bicep) deploys:

- private DNS zones for commercially available Azure Private Link domains
- links from those zones to a hub virtual network
- an Azure Private DNS Resolver with an inbound endpoint

This lets spoke networks and on-premises networks resolve private endpoint records through a shared DNS layer rather than duplicating zones across multiple landing zones or subscriptions.

## Why Use This Pattern

Deploying the zones centrally ahead of time gives application and operations teams a controlled place to manage DNS records without giving broad rights to create new Private DNS zones wherever they want.

Recommended operating model:

- host the Private DNS zones in a dedicated resource group
- delegate record management to the appropriate team, for example with `Private DNS Zone Contributor`
- keep the resolver in the hub network that can service spoke and hybrid name resolution

> [!TIP]
> Private DNS zones are global resources. They do not need to live in the same resource group as the hub virtual network.

> [!WARNING]
> This template deploys an Azure Private DNS Resolver with an inbound endpoint. That resource is billable. Review [Azure Private DNS Resolver pricing](https://azure.microsoft.com/en-in/pricing/details/dns) before deployment.

## Related Governance Template

The [AzPolicy/README.md](./AzPolicy/README.md) folder contains a companion governance deployment.

That management-group-scoped policy is intended to support this centralized DNS pattern by denying creation of Azure Private DNS zones outside the approved DNS resource group. Use it when you want to enforce that all Private DNS zones stay in the central DNS landing zone instead of being scattered across application resource groups.

This will also block auto generated DNS zones during resource creation, keeping DNS zones centralized.

## Prerequisites

- Azure PowerShell installed
- Contributor or equivalent rights over the target resource group
- A hub virtual network already in place
- A subnet for the resolver inbound endpoint that is either dedicated or safely sized for the resolver

## Deploy

Deploy the template at resource-group scope:

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName '<your-resource-group>' `
  -TemplateFile './dns_zones_and_resolver.bicep'
```

## Parameters

| Parameter                                    | Description                                                                                                        |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `hub_vnet_externalid`                        | Resource ID of the hub virtual network. See [Getting The Hub vNET Resource ID](#getting-the-hub-vnet-resource-id). |
| `hub_vnet_resolver_subnet`                   | Resource ID of the subnet that will host the resolver inbound endpoint.                                            |
| `private_dns_resolver_name`                  | Name of the Azure Private DNS Resolver resource.                                                                   |
| `private_dns_resolver_inbound_endpoint_name` | Name of the inbound endpoint resource under the resolver.                                                          |
| `hub_vnet_location`                          | Azure region code for the hub virtual network and inbound endpoint deployment.                                     |

> [!IMPORTANT]
> `hub_vnet_location` must use the Azure programmatic region name such as `canadacentral`, `eastus`, or `westeurope`, not the display label shown in the portal.

## Inbound Endpoint Subnet Requirements

The subnet used for the resolver inbound endpoint must:

- be between `/28` and `/24`
- be reachable by the spoke and hybrid networks that will send DNS queries to it

If address space allows, use a dedicated subnet for the resolver.

## Getting The Hub vNET Resource ID

1. Open the hub virtual network in the Azure portal and select **JSON View**.

   ![JSON View](JSON%20View.png)

2. Copy the **Resource ID** value.

   ![Copy Resource ID](Copy%20Resource%20ID.png)

## Post-Deployment Steps

After deployment, complete the downstream DNS configuration:

1. Configure on-premises DNS conditional forwarders for the relevant `privatelink.*` zones so they point to the resolver inbound endpoint IP.
2. Configure spoke virtual networks to use the resolver inbound endpoint IP as their DNS server if you want them to resolve through the centralized path.

## DNS Resolution Architecture

Azure private DNS behavior depends on where the DNS query originates. For a private zone record to resolve correctly, Azure must see the request as coming from a network context linked to the zone. The inbound endpoint on the Private DNS Resolver gives you a central place to receive DNS queries and forward them through that linked hub network context.

![DNS Resolution Architecture](DNS%20Resolution.jpg)
