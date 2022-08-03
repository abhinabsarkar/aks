# Azure Policy for Kubernetes clusters
Azure Policy extends [Gatekeeper](https://github.com/open-policy-agent/gatekeeper) v3, an admission controller webhook for [Open Policy Agent (OPA)](https://www.openpolicyagent.org/), to apply at-scale enforcements and safeguards on your clusters in a centralized, consistent manner. Azure Policy makes it possible to manage and report on the compliance state of your Kubernetes clusters from one place. The add-on enacts the following functions:
* Checks with Azure Policy service for policy assignments to the cluster.
* Deploys policy definitions into the cluster as [constraint template](https://open-policy-agent.github.io/gatekeeper/website/docs/howto/#constraint-templates) and [constraint](https://github.com/open-policy-agent/gatekeeper#constraints) custom resources.
* Reports auditing and compliance details back to Azure Policy service.

## Azure Policy for AKS
### Disable default service accont automount on AKS
There is built-in policy for disallowing automounting service token: [Kubernetes clusters should disable automounting API credentials](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F423dd1ba-798e-40e4-9c4d-b6902674b423)
  * [Default service accounts in K8s explained - youtube](https://www.youtube.com/watch?v=fJCT_YW2e6M)

The complete list of Azure Policy built-in definitions for Azure Kubernetes Service can be found here: https://docs.microsoft.com/en-us/azure/aks/policy-reference

## Refernces
https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes
