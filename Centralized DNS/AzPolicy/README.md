# DNS Zone Governance Policy

This folder contains a management-group-scoped Azure Policy deployment that denies creation of Azure Private DNS zones outside one approved resource group.

Use this alongside the main centralized DNS deployment in the parent folder when you want both:

- a standard location for centrally managed Private DNS zones
- a policy guardrail that prevents teams from creating those zones elsewhere

## What The Parameter Is For

The Bicep template prompts for `dedicatedPrivateDnsRg`.

That parameter is the **name of the one approved resource group** where Azure Private DNS zones are allowed to exist. The policy assignment passes that value into the policy rule, and any attempt to create `Microsoft.Network/privateDnsZones` in a different resource group is denied.

Typical use case:

- Your platform team hosts centrally managed private DNS zones in a dedicated resource group.
- Application teams can link to or use those zones, but they should not create their own duplicate zones in random resource groups.

## What Gets Deployed

The deployment in [dns-zone-governance.bicep](./dns-zone-governance.bicep) creates:

- a custom policy definition named `deny-private-dnszones-outside-dnsrg`
- a policy assignment named `assign-dnszones-dnsrg`

Both resources are deployed at **management group scope**.

## Prerequisites

- You are connected to the correct tenant and subscription context
- You have permission to create policy definitions and assignments at the target management group

Sign in before running the deployment:

```powershell
Connect-AzAccount
```

## Deploy With Azure PowerShell

> [!IMPORTANT]
> The `-Location` value is required for management group deployments because Azure stores deployment metadata in a region. It is not the location of the policy itself.

Deploy after reviewing the what-if output:

```powershell
New-AzManagementGroupDeployment -ManagementGroupId [Management Group ID] -Location [Location to Store Policy] -TemplateFile ./dns-zone-governance.bicep
```

When prompted for "dedicatedPrivateDnsRg" provide the name of the resource group where you intend to allow Private DNS Zone creation

## Recommended Usage

Deploy this policy when the parent template in [../readme.md](../readme.md) is being used as the standard centralized DNS pattern for your environment.

That combination gives you:

- centralized Private DNS zones and resolver infrastructure
- a governance control that keeps all Private DNS zones in the approved DNS resource group
- a clearer operating model for platform and application teams
