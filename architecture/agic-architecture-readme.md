# Application Gateway Ingress Controller for AKS

## Overview
Released on Dec 2nd, 2019, uses open source [Application Gateway Ingress Controller (AGIC)](https://github.com/Azure/application-gateway-kubernetes-ingress) for Kubernetes - [link](https://azure.microsoft.com/en-us/blog/application-gateway-ingress-controller-for-azure-kubernetes-service/). AGIC runs as a pod in the customer's AKS.

### Benefits
Application Gateway Ingress Controller leverages Azure’s native Application Gateway L7 load balancer & provides benefits like :
* Performance - It eliminates the need to have another load balancer/public IP in front of AKS cluster and avoids multiple hops in the datapath. Application Gateway talks to pods using their private IP directly and does not require NodePort or KubeProxy services.
* Security - protects AKS cluster by providing TLS policy and Web Application Firewall (WAF)
* Auto scaling - It scales without consuming any resources from AKS cluster
* Other benefits include URL routing (Path based as well as Hostname based), cookie based affinity, etc

## In-Cluster Ingress Controller vs Application Gateway Ingress Controller

![Alt text](/images/icic-vs-agic.jpg)

An in-cluster load balancer performs all data path operations leveraging the Kubernetes cluster’s compute resources. It competes for resources with the business apps it is fronting. In-cluster ingress controllers create Kubernetes Service Resources and leverage [kubenet](aks-networking-readme.md#Kubenet-(Basic)-networking) for network traffic.

AGIC leverages the AKS’ [advanced networking](aks-networking-readme.md#Azure-CNI-(advanced)-networking), which allocates an IP address for each pod from the subnet shared with Application Gateway. Application Gateway has direct access to all Kubernetes pods.

## How it works?
AGIC runs in its own pod on the customer’s AKS. It monitors a subset of Kubernetes Resources for changes. The state of the AKS cluster is translated to App Gateway specific configuration and applied to the Azure Resource Manager (ARM). AGIC is configured via the Kubernetes Ingress resource, along with Service and Deployments/Pods.

![Alt text](/images/aks-agic.jpg)

When an application is deployed in the AKS cluster, typically it will have definition of a pod, service & the ingress resource. AGIC monitors the kubernetes ingress resources & translate them to ARM templates. These ARM templates are applied to Application Gateway resource in Azure, which configures the backend address pool & other configurations. These configurations once updated, the Application Gateway routes traffic directly to the application pods.

## AAD Pod Identities with AGIC in AKS
Role Based Access Control (RBAC) plays an important role for the AGIC to update the configurations on Application Gateway. It should be done by creating a user-assigned managed identity & associating it with AGIC. For AGIC to update the Application Gateway, the AGIC identity is granted *contributor* role on the Application Gateway & *reader* role on the Application Gateway resource group. Also, AKS requires a service principal to create the resources it needs for setting up the cluster. The service principal must be granted *managed identity operator* on the identity. To understand more about the managed identities & pod identities, refer [Managed Identity & AAD Pod Identity](pod-mi-readme.md).

## AGIC in action
To see AGIC in action, follow this [link](/concepts/aks-agic-readme.md)  

## Automate using Terraform
Create an Application Gateway ingress controller in Azure Kubernetes Service - [link](https://docs.microsoft.com/en-us/azure/developer/terraform/create-k8s-cluster-with-aks-applicationgateway-ingress)
