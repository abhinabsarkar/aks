# Hello AKS cluster
Let's see AKS in action by creating an AKS cluster, hosting an application & accessing it from browser.

## Create an AKS cluster
```bash
# Azure login using cli
az login
# Create a resource group
az group create --name rg-aks-demo --location eastus --verbose
# Create an AKS cluster
az aks create --resource-group rg-aks-demo --name aks-abs-demo --node-count 1 --generate-ssh-keys --verbose
# Get the AKS credentials - download credentials and configure the Kubernetes CLI
az aks get-credentials --resource-group rg-aks-demo --name aks-abs-demo --verbose
# Access the cluster using kubectl to verify connection
kubectl get nodes --v=9
```

## Kubernetes dashboard
Kubernetes dashboard can be used for management of cluster, view basic health status and metrics for applications, create and deploy services, and edit existing applications.
```bash
# AKS cluster uses RBAC, a ClusterRoleBinding must be created before you can correctly access the dashboard. By default, the Kubernetes dashboard is deployed with minimal read access and displays RBAC access errors. This sample binding does not apply any additional authentication components and may lead to insecure use
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
# Start kubernetes dashboard - This command creates a proxy between your development system and the Kubernetes API, and opens a web browser to the Kubernetes dashboard.
az aks browse --resource-group rg-aks-demo --name aks-abs-demo
```
## Run a dockerized application on AKS cluster via kubernetes dashboard
In the below example, a python application image is run on AKS service. The python application is exposed on port 5000 & available publicly on docker hub.
![Alt Text](/images/k8s-dashboard.jpg)

The application is exposed as an External service on AKS cluster and can be browsed by using the External IP created by Azure.
![Alt Text](/images/hello-python.jpg)

## Run a dockerize application on AKS cluster via kuberbetes manifest
Kubernetes manifest file defines a desired state for the cluster. This manifest [azure-vote.yaml](/src/azure-vote.yaml) includes two [Kubernetes deployments](https://docs.microsoft.com/en-us/azure/aks/concepts-clusters-workloads#deployments-and-yaml-manifests) - one for the sample Azure Vote Python applications, and the other for a Redis instance. Two [Kubernetes Services](https://docs.microsoft.com/en-us/azure/aks/concepts-network#services) are also created - an internal service for the Redis instance, and an external service to access the Azure Vote application from the internet.

```bash
kubectl apply -f azure-vote.yaml --v=9
kubectl get service azure-vote-front --watch
```
To see the Azure Vote app in action, open a web browser to the external IP address of your service.

## Run dockerized application on Azure Dev Spaces
Rather than creating applications manually using kubernetes dashboard or manifest files, [Azure Dev Spaces](https://docs.microsoft.com/en-us/azure/dev-spaces/how-dev-spaces-works) can be used in conjunction with IDE (Visual Studio or Visual Studio Code) for iterative development and debugging of micro-services on AKS. 

```bash
# Enable dev spaces - Create a dev space in AKS. This will also install the Dev Space cli
az aks use-dev-spaces --resource-group rg-aks-demo --name aks-abs-demo --verbose
```
Refer this [link](https://docs.microsoft.com/en-us/azure/dev-spaces/quickstart-netcore) to run a sample application using IDE on Dev Spaces.

### **Azure Dev Spaces code configuration**
Azure Dev Spaces uses the [azds.yaml](/src/azds.yaml) file to install and configure your service. The controller uses the install property in the azds.yaml file to install the Helm chart and create the Kubernetes objects like Ingress Controller (Traefik), deployment pods, application pods, replica sets. Refer this [link](https://docs.microsoft.com/en-us/azure/dev-spaces/how-dev-spaces-works#how-routing-works) to see how the code is configured to run Azure Dev Spaces.

### **Azure Dev Spaces Routing**
Azure Dev Spaces also has a centralized ingressmanager service and deploys its own Ingress Controller to the AKS cluster.

When an HTTP request is made to a service from outside the cluster, the request goes to the Ingress controller. The Ingress controller routes the request directly to the appropriate pod based on its Ingress objects and rules. The devspaces-proxy container in the pod receives the request, adds the azds-route-as header based on the URL, and then routes the request to the application container.

When an HTTP request is made to a service from another service within the cluster, the request first goes through the calling service's devspaces-proxy container. The devspaces-proxy container looks at the HTTP request and checks the azds-route-as header. Based on the header, the devspaces-proxy container will look up the IP address of the service associated with the header value. If an IP address is found, the devspaces-proxy container reroutes the request to that IP address. If an IP address is not found, the devspaces-proxy container routes the request to the parent application container.

![Alt Text](/images/azds-routing.jpg)

Refer this [link](https://docs.microsoft.com/en-us/azure/dev-spaces/how-dev-spaces-works#how-routing-works) for details.

## Delete the AKS cluster
AKS automatically deletes the node resource whenever the cluster is deleted. Refer this [link](https://docs.microsoft.com/bs-latn-ba/azure/aks/faq#why-are-two-resource-groups-created-with-aks) for details.
```bash
# Delete the cluster which will also delete the resource group. AKS automatically deletes the node resource  group whenever the cluster is deleted
az group delete --name rg-aks-demo --yes --no-wait --verbose
```