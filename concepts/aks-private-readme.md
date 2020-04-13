# AKS Private Cluster
In a private AKS cluster, the control plane or API server has internal IP addresses i.e. the API server endpoint has no public IP address. To manage the API server, you will need to use a VM that has access to the AKS cluster's Azure Virtual Network (VNet). To establish network connectivity with the private cluster, use one of the following options:
* Create a VM in the same Azure Virtual Network (VNet) as the AKS cluster.
* Use a VM in a separate network and set up Virtual network peering.
* Use an Express Route or VPN connection

The API server (which is managed by Microsoft) and the cluster/node pool (managed by customer) communicate with each other through the [Azure Private Link service](https://docs.microsoft.com/en-us/azure/private-link/private-link-service-overview) in the API server virtual network and a [private endpoint](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) that's exposed in the subnet of the customer's AKS cluster.

## AKS private cluster in action
Create an AKS private cluster.
> *The bash scripts can be found [here](/src/aks-private)*
```bash
# Login to azure using the service principal scoped to a resource group
# Pass the service principal's username, password & tenanat ID
./login-az.sh <sp-client-id> <sp-client-secret> <tenant-id>

# Create VNET. Create AKS private cluster & attach the subnet to it
# Pass the service principal username, secret & subscription id
./create-aks-private.sh <sp-client-id> <sp-client-secret> <subscription-id>
```
The above script will create a private AKS cluster and the resources as shown below.  
**Resource group rg-aks-test**  
![Alt text](/images/aks-private-cluster-vnet.jpg)  
**Resource group MC_rg-aks-test_aks-test_eastus2**  
![Alt text](/images/aks-private-resources.jpg)  

If you try to access the API server using kubectl client from a system which is not in the same VNet, it won't be accessible.  

![Alt text](/images/aks-private-unreachable.jpg) 

To access the API server, in this example we create a VM in the same VNet.
```bash
# Create VM in the same VNET
# Pass the VM user name & password
./create-vm.sh <vm-user-name> <vm-password>
```
The above script will create a VM in the same VNet under the resource group rg-aks-test. The resources can be seen below.  

![Alt text](/images/aks-private-vm.jpg)  

If you try to access the k8s API server from this VM, it will be reachable.  

![Alt text](/images/aks-private.jpg)  

To avoid charges on the Azure account, delete the resources by running the script below.
```bash
# Delete the VM and associated resources
./delete-vm-n-resources.sh

# Delete the AKS cluster, not the resource group
./delete-aks.sh

# Delete the VNet
./delete-vnet.sh

# Logout from Azure
# Pass the service principal username 
./logout-az.sh <sp-client-id>
```

### References
[Azure AKS private cluster](https://docs.microsoft.com/en-us/azure/aks/private-clusters)  
[Azure Private Link](https://docs.microsoft.com/en-us/azure/private-link/private-link-overview)  
[Private Azure Kubernetes Service cluster](https://docs.microsoft.com/en-us/azure/aks/private-clusters)