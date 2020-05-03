# Managed Identity & AAD Pod Identity

### Problem Statement
Managing credentials in the application code is a common challenge that is faced while building the cloud native applications. The common issues that are faced by enterprises are as follows:
* managing secrets when they expire & periodic credential rotation
* auditing the service principal (automation account) which accessed the secured service

### Solution - Managed Identity
Managed Identity - It provides Azure services with an automatically managed identity in Azure AD, which is used to authenticate to any service that supports Azure AD authentication. Azure takes care of rolling the credentials that are used by the service instance.

### How it works?
Internally, managed identities are service principals of a special type, which are locked to only be used with Azure resources. If Managed Identity is enabled for a Azure service like VM or AKS, a service principal is created in Azure AD. This is called as **system-assigned MI**. After the identity is created, the credentials are provisioned onto the Azure service instance. The identity on the resource is configured by updating the Azure Instance Metadata Service (IMDS) endpoint with the service principal client ID and certificate. The lifecycle of a system-assigned identity is directly tied to the Azure service instance that it's enabled on. If the instance is deleted, Azure automatically cleans up the credentials and the identity in Azure AD. RBACs are used to grant access to a resource & this has to be done explicitly for the system-assigned identity.

![Alt text](/images/msi.jpg)

It is also possible to create a **user-assigned MI** as a standalone azure resource. After the identity is created, the identity can be assigned to one or more Azure service instances. The lifecycle of a user-assigned identity is managed separately from the lifecycle of the Azure service instances to which it's assigned. RBACs are used to grant access to a resource & this has to be done explicitly for the user-assigned identity.

## AAD Pod Identities
In AKS, pods need access to other Azure services, say Cosmos DB or Key Vault. Rather than defining the credentials in container image or injecting as kubernetes secret, the best practice is to use managed identities.
> Managed pod identities is an open source project, and as of May 1st, 2020, it is not supported by Azure technical support.

In AKS, two components are deployed by the cluster operator to allow pods to use managed identities:
* **Node Management Identity (NMI) server** - It is a pod that runs as a [DaemonSet](https://github.com/abhinabsarkar/k8s-networking/blob/master/concepts/pod-readme.md#daemonset) on each node in the AKS cluster. The NMI server listens for pod requests to Azure services.
* **Managed Identity Controller (MIC)** - It is a central pod with permissions to query the Kubernetes API server and checks for an Azure identity mapping that corresponds to a pod.

When pods request access to an Azure service, network rules redirect the traffic to the Node Management Identity (NMI) server. The NMI server identifies pods that request access to Azure services based on their remote address, and queries the Managed Identity Controller (MIC). The MIC checks for Azure identity mappings in the AKS cluster, and the NMI server then requests an access token from Azure Active Directory (AD) based on the pod's identity mapping. Azure AD provides access to the NMI server, which is returned to the pod. This access token can be used by the pod to then request access to services in Azure.

![Alt text](/images/pod-identities.jpg)

In the above example, a developer creates a pod that uses a managed identity to request access to an Azure SQL Server instance:
1. Cluster operator first creates a service account that can be used to map identities when pods request access to services.
2. The NMI server and MIC are deployed to relay any pod requests for access tokens to Azure AD.
3. A developer deploys a pod with a managed identity that requests an access token through the NMI server.
4. The token is returned to the pod and used to access an Azure SQL Server instance.

## References
https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview  
https://docs.microsoft.com/en-us/azure/aks/operator-best-practices-identity  
https://github.com/Azure/aad-pod-identity  
https://medium.com/@harioverhere/using-aad-podidentity-with-azure-kubernetes-service-42a53fd04006