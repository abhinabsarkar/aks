# Azure Kubernetes Service

Azure Kubernetes Service (AKS) manages hosted Kubernetes environment. As a hosted Kubernetes service, the Kubernetes masters are managed by Azure. Customers only manage, maintain and pay for the agent nodes. Azure handles tasks like health monitoring and maintenance for the customers.

* [Kubernetes Architecture & Concepts](/architecture/k8s-readme.md)
    * [Install Kubernetes for Development](/concepts/k8s-dev-install-readme.md)
* [AKS Architecture & Concepts](/architecture/aks-readme.md)
* [Role-based access control using Azure AD](/concepts/aks-rbac-aad-readme.md)
    * [Implementing Azure AD integration with AKS](/concepts/aks-aad-integration.md)
* [Hello AKS cluster](/concepts/hello-aks.md)
* Kubernetes Concepts
    * [Ingress](/concepts/ingress-readme.md)
        * [Enable an Ingress Controller for AKS - Development Only](/concepts/http-application-routing-readme.md)
        * [Enable an HTTPS NGINX Ingress Controller - Recommended for Production](https://docs.microsoft.com/en-us/azure/aks/ingress-tls)
    * [Service](/concepts/service-readme.md)