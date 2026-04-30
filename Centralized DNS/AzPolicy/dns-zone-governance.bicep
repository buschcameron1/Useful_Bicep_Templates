targetScope = 'managementGroup'

@description('Policy assignment name.')
param assignmentName string = 'assign-dnszones-dnsrg'

@description('Approved resource group name for Azure Private DNS zones (Microsoft.Network/privateDnsZones).')
param dedicatedPrivateDnsRg string

@description('Category shown in Azure Policy.')
param policyCategory string = 'Network'

@description('Version stamped into policy metadata.')
param policyVersion string = '1.0.0'

var policyOwner = 'Platform Engineering'

resource privateDnsPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'deny-private-dnszones-outside-dnsrg'
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Deny Private DNS zone creation outside dedicated DNS resource group'
    description: 'Denies creation of Azure Private DNS zones unless they are deployed into the approved dedicated DNS resource group.'
    metadata: {
      category: policyCategory
      version: policyVersion
      owner: policyOwner
      source: 'Bicep + external JSON policy rule'
    }
    parameters: {
      dnsResourceGroupName: {
        type: 'String'
        metadata: {
          displayName: 'Dedicated Private DNS resource group name'
          description: 'Only this resource group is allowed to host Azure Private DNS zones.'
        }
      }
    }
    policyRule: loadJsonContent('./deny-private-dnszones-outside-dnsrg.json')
  }
}

resource dnsZoneGovernanceAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: assignmentName
  properties: {
    displayName: 'Assign DNS zone governance guardrails'
    description: 'Assigns policy that denies Private DNS zones outside dedicated resource group.'
    policyDefinitionId: privateDnsPolicy.id
    enforcementMode: 'Default'
    parameters: {
      dnsResourceGroupName: {
        value: dedicatedPrivateDnsRg
      }
    }
    nonComplianceMessages: [
      {
        message: 'Create Azure Private DNS zones only in the approved dedicated DNS resource group.'
      }
    ]
  }
}

output privateDnsPolicyDefinitionId string = privateDnsPolicy.id
output assignmentId string = dnsZoneGovernanceAssignment.id
