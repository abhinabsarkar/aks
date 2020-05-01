# AKS Networking
In AKS, a cluster can be deployed using one of the two network models:

* Kubenet networking - The network resources are typically created and configured as the AKS cluster is deployed.
* Azure Container Networking Interface (CNI) networking - The AKS cluster is connected to existing virtual network resources and configurations.

## Kubenet (Basic) networking
With kubenet, only the *nodes* receive an IP address in the virtual network *subnet*. Pods can't communicate directly with each other. Instead, User Defined Routing (UDR) and IP forwarding is used for connectivity between pods across nod.  
![Alt text](/images/kubenet.jpg)

## Azure CNI (advanced) networking
With Azure CNI, every *pod* gets an IP address from the virtual network *subnet* and can be accessed directly. A pool of IP addresses for the Pods is configured as secondary addresses on a virtual machine's network interface. Azure CNI sets up the basic Network connectivity for Pods and manages the utilization of the IP addresses in the pool. When a Pod comes up in the virtual machine, Azure CNI assigns an available IP address from the pool and connects the Pod to a software bridge in the virtual machine. When the Pod terminates, the IP address is added back to the pool.

![Alt text](/images/azure-cni.jpg)

The Azure Virtual Network container network interface (CNI) plug-in installs in an Azure Virtual Machine. The plug-in assigns IP addresses from a virtual network to containers brought up in the virtual machine, attaching them to the virtual network, and connecting them directly to other containers and virtual network resources. The plug-in doesn’t rely on overlay networks, or routes, for connectivity, and provides the same performance as virtual machines.

The following picture shows how the plug-in provides Azure Virtual Network capabilities to Pods:  
![Alt text](/images/azure-cni-plugin.jpg)

## References
https://docs.microsoft.com/en-us/azure/aks/configure-kubenet  
https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni  
https://docs.microsoft.com/en-us/azure/virtual-network/container-networking-overview  
https://docs.microsoft.com/en-us/azure/aks/concepts-network  