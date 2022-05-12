# FAQs
* Does AKS support Windows containers? Yes
    * [Windows Server Container FAQs - Microsoft](https://docs.microsoft.com/en-us/azure/aks/windows-faq)
    * [Create a Windows Server container on an AKS cluster - Microsoft](https://docs.microsoft.com/en-us/azure/aks/windows-container-cli)
    * [Windows container isolation modes - Microsoft](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/hyperv-container)
* What is a node pool? In Azure Kubernetes Service (AKS), nodes of the same configuration are grouped together into node pools. Node pools contain the underlying VMs that run your applications. System node pools and user node pools are two different node pool modes for your AKS clusters. System node pools serve the primary purpose of hosting critical system pods such as CoreDNS and metrics-server. User node pools serve the primary purpose of hosting your application pods. However, application pods can be scheduled on system node pools if you wish to only have one pool in your AKS cluster. Every AKS cluster must contain at least one system node pool with at least one node.
* How CoreDNS works?
* What is tunnelfront?
* What is the VM image for cluster node in AKS? Ubuntu Linux or Windows Server 2019. If you need advanced configuration and control on your Kubernetes node container runtime and OS, you can deploy a self-managed cluster using [Cluster API Provider Azure](https://docs.microsoft.com/en-us/azure/aks/concepts-clusters-workloads).
* How much of the resources in AKS worker node is available for workloads? [Resource reservations](https://docs.microsoft.com/en-us/azure/aks/concepts-clusters-workloads#resource-reservations) 
* How to design a AKS cluster?
    * Node Size
    * Networking, IP addressing
    * App Monitoring
    * Auto-scaling
    * Ingress
    * Security
        * Authentication, Azure AD integration
        * Pod Identity
        * RBAC
    * Service Mesh
    * CI/CD
* How the day 2 operations are managed on AKS?
    * Upgraidng the cluster
    * Infra Monitoring
    * Alerting
