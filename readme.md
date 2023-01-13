# Azure Kubernetes Service

Azure Kubernetes Service (AKS) manages hosted Kubernetes environment. As a hosted Kubernetes service, the Kubernetes masters are managed by Azure. Customers only manage, maintain and pay for the agent nodes. Azure handles tasks like health monitoring and maintenance for the customers.

![alt txt](/images/aks-configuration.jpg)

* [Basic concepts](https://github.com/abhinabsarkar/k8s-networking/blob/master/concepts/pod-readme.md)
* [Kubernetes Architecture & Concepts](/architecture/k8s-readme.md)
    * [Install Kubernetes for Development](/concepts/k8s-dev-install-readme.md)
    * [Kubernetes networking](https://github.com/abhinabsarkar/k8s-networking/blob/master/concepts/k8s-networking-readme.md)
* [AKS Architecture & Concepts](/architecture/aks-readme.md)
    * [AKS Networking](/architecture/aks-networking-readme.md)
    * [Azure Load Balancing](https://github.com/abhinabsarkar/azure-loadbalancing)
* [Role-based access control using Azure AD](/concepts/aks-rbac-aad-readme.md)
    * Deprecated ~~[Implementing Azure AD integration with AKS](/concepts/aks-aad-integration.md)~~
    * [AKS integration with Azure AD - Microsoft](https://docs.microsoft.com/en-us/azure/aks/azure-ad-v2)
        * [AKS RBAC best practices](/concepts/AKS-RBAC-BestPractices.pdf)
        * [AKS with AAD & RBAC - Demo](/concepts/aks-aad-readme.md)
    * [Managed Identity & Pod Identity](/architecture/pod-mi-readme.md)
* [Hello AKS cluster](/concepts/hello-aks.md)
* AKS Kubernetes Concepts
    * [Ingress](/concepts/ingress-readme.md)
        * [Enable an Ingress Controller for AKS - Development Only](/concepts/http-application-routing-readme.md)
        * [Nginx Ingress Controller with internal load balancer](https://github.com/abhinabsarkar/aks-ingress-ilb)
            * [TLS (HTTPS) NGINX Ingress Controller - Production](https://docs.microsoft.com/en-us/azure/aks/ingress-tls)
        * [Enable an Application Gateway Ingress Controller](/architecture/agic-architecture-readme.md)
            * [Application Gateway Ingress Controller in action](/concepts/aks-agic-readme.md)        
            * [Secure AKS service over HTTPS - Application Gateway to AKS service](https://docs.microsoft.com/en-us/azure/application-gateway/ingress-controller-expose-service-over-http-https#expose-services-over-https)
            * [TLS termination and end to end TLS with Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/ssl-overview)
* [AKS - OS configuration, Container runtime](https://learn.microsoft.com/en-us/azure/aks/cluster-configuration#os-configuration)
* [AKS cluster egress traffic](/concepts/egress-outboundtype-aks.md)
    * Explains egress traffic configurations, outbound connectivity methods & outbound rules.
* [AKS Node Pools](/concepts/nodepools-readme.md)
* [AKS Private cluster](/concepts/aks-private-readme.md)
* [AKS Best Practices from Microsoft](/concepts/AKS-Best_practices.pdf)
* [AKS cluster hardening using policies](/concepts/aks-policies-readme.md)
* [Open Service Mesh - demo](https://github.com/abhinabsarkar/osm/blob/main/src/cli-aks-osm-demo.md)
* [Logging & Monitoring](/concepts/log-monitor-readme.md)
    * [Local account in AKS & audit logs](/concepts/local-account-auditlogs-readme.md)
* [Connect to AKS nodes](/concepts/node-access-readme.md)
* [Running stateful Spring Boot App on AKS](https://github.com/abhinabsarkar/spring-boot-demo/blob/main/concepts/sb-stateful-aks-readme.md)
* [AKV provider for Secrets Store CSI driver in AKS](/concepts/akv-csi-driver-readme.md)
* [FAQs](/concepts/faq.md)
