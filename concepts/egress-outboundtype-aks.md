# AKS Egress traffic
The outbound traffic for an AKS cluster can be customized to fit specific scenarios. This is determined by the property defined as `outboundtype`. The different accepted values are `[--outbound-type {loadBalancer, managedNATGateway, userAssignedNATGateway, userDefinedRouting}]` where the value `loadbalancer` is the default.
* [Outboundtype in az cli create command](https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az-aks-create)

## Outbound type of loadBalancer
The load balancer is used for egress through an AKS assigned public IP. An outbound type of loadBalancer supports Kubernetes services of type loadBalancer. The following configuration is done by AKS.
* A public IP address is provisioned for cluster egress.
* The public IP address is assigned to the load balancer resource.
* Backend pools for the load balancer are set up for agent nodes in the cluster.
* Outbound rules uses the public IP(s) of load balancer for outbound connectivity. The request starts from AKS nodes to loadbalancer's outbound Public IP. 
    * Refer [Azure's outbound connectivity methods](https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#scenarioshttps://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#scenarios)
    * Refer [Outbound rules Azure Load Balancer](https://learn.microsoft.com/en-us/azure/load-balancer/outbound-rules)

[Outboundtype Loadbalancer](https://learn.microsoft.com/en-us/azure/aks/egress-outboundtype#outbound-type-of-loadbalancer)

![alt txt](/images/outboundtype-lb.png)

## Outbound type of userDefinedRouting
If userDefinedRouting is set, AKS won't automatically configure egress paths
* To use the `userDefinedRouting`, the cluster must be associated with an existing VNet subnet when created.
* The existing VNet subnet must have a routing table associated (to manage egress). It must have at least the default (0.0.0.0/0) route. 
* If using Assigned Identity and kubenet, you need to use User Assigned Identity. Route tables are not supported with System Assigned with kubenet. No issues with System Assigned Identity with Azure network plugin.
* If you use the “userDefinedRouting” but don’t actually provide valid routes, then the cluster will be created but will fail to deploy system pods, since it can’t download the images. Refer MS doc - [Required outbound network rules and FQDNs for AKS clusters](https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic#required-outbound-network-rules-and-fqdns-for-aks-clusters)
* When using an outbound type of UDR, a standard load balancer (SLB) is created only when the first Kubernetes service of type 'loadBalancer' is deployed. A public IP address for outbound requests is never created by AKS if an outbound type of UDR is set.

```bash
# Create a kubernetes cluster with userDefinedRouting, standard load balancer SKU and 
# a custom subnet preconfigured with a route table
az aks create -g MyResourceGroup -n MyManagedCluster \
    --outbound-type userDefinedRouting --load-balancer-sku standard \
    --vnet-subnet-id customUserSubnetVnetID
```

[Outboundtype userDefinedRouting](https://learn.microsoft.com/en-us/azure/aks/egress-outboundtype#outbound-type-of-userdefinedrouting)

To illustrate the application of a cluster with outbound type using a user-defined route, a cluster can be configured on a virtual network with an Azure Firewall on its own subnet. See [Restrict egress traffic using Azure firewall](https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic#restrict-egress-traffic-using-azure-firewall)

![alt txt](/images/aks-azure-firewall-egress.png)

> See this for [SNAT vs DNAT](https://www.geeksforgeeks.org/difference-between-snat-and-dnat/)

* Public Ingress is forced to flow through firewall filters
    * A DNAT rule translates the FW public IP into the LB frontend IP.
* Outbound requests start from agent nodes to the Azure Firewall internal IP using a user-defined route
    * Requests from AKS agent nodes follow a UDR that has been placed on the subnet the AKS cluster was deployed into.
    * Azure Firewall egresses out of the virtual network from a public IP frontend
    * Access to the public internet or other Azure services flows to and from the firewall frontend IP address
    * Optionally, access to the AKS control plane is protected by API server Authorized IP ranges, which includes the firewall public frontend IP address.
* Internal Traffic
    * Optionally, instead or in addition to a Public Load Balancer you can use an Internal Load Balancer for internal traffic, which you could isolate on its own subnet as well.

Refer the steps for implementation [Control egress traffic for cluster nodes in Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic) or create the AKS cluster using [Azure Kubernetes Service (AKS) Baseline Cluster](https://github.com/mspnp/aks-baseline) or [AKS Secure Baseline with Private Cluster](https://github.com/Azure/AKS-Landing-Zone-Accelerator/tree/main/Scenarios/AKS-Secure-Baseline-PrivateCluster).

## Outboundtype of managedNATGateway & userAssignedNATGateway

Virtual Network NAT gateway is a Network Address Translation (NAT) service. When it is configured on a subnet, all outbound connectivity uses the Virtual Network NAT's static public IP addresses. Refer [Virtual Network NAT](https://learn.microsoft.com/en-us/azure/virtual-network/nat-gateway/nat-overview) for basics & details on the configuration.

![alt txt](/images/flow-map.png)

When connected with a subnet, outbound connectivity is possible without load balancer or public IP addresses directly attached to virtual machines. A NAT gateway is highly extensible, reliable, and doesn't have the same concerns of SNAT port exhaustion. 
    * [Associate a NAT gateway to the subnet](https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#2-associate-a-nat-gateway-to-the-subnet)
    * [SNAT ports & how they work](https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#what-are-snat-ports)
    * [Port exhaustion](https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#port-exhaustion)

![alt txt](/images/nat-gateway.png)

Whilst AKS can route egress traffic through an Azure Load Balancer, there are limitations on the amount of outbound flows of traffic that is possible. Azure NAT Gateway allows up to 64,512 outbound UDP and TCP traffic flows per IP address with a maximum of 16 IP addresses.

```bash
# Create a kubernetes cluster with a AKS managed NAT gateway, 
# with two outbound AKS managed IPs an idle flow timeout of 4 minutes
az aks create -g MyResourceGroup -n MyManagedCluster \
    --nat-gateway-managed-outbound-ip-count 2 --nat-gateway-idle-timeout 4 \
    --outbound-type managedNATGateway --generate-ssh-keys
```

Refer [AKS using NAT Gateway as outbound type](https://learn.microsoft.com/en-us/azure/aks/nat-gateway) for implementation.

