# AKS with Application Gateway Ingress Controller

Create an AKS cluster with Application Gateway Ingress controller & AAD pod identity (Managed Identity)

Use case - System admin will create a Resource Group and provide a service account with contributor access to the application team

## System admin tasks - set up the resource group & service principal
### Creating Azure Resources
* Create a Resource Group
```bash
# Create a resource group
az group create -n rg-aksAgicPmi -l eastus2 --tags Identifier=abs-aksAgicPmi-main --verbose
```
* Create a service principal which will be used as automation account & assign it contributor access on the resource group created above
```bash
# Get the resource group id & subscription id (required for creating aks cluster later)
rgId=$(az group show -n rg-aksAgicPmi --query id -o tsv)
subscriptionId=$(az account show --query id -o tsv)
# Create a service principal & assign it contributor access to the resource group. Output it to json
az ad sp create-for-rbac --name sp-aksAgicPmi --role contributor \
    --scope $rgId \
    -o json > auth.json
# Check the service principal details
az ad sp list --display-name sp-aksAgicPmi
# Check the role assignment
az role assignment list --scope $rgId -o table
```

## DevOps tasks - create AKS cluster with Application Gateway
### Creating Azure Resources
* Create an AKS cluster with no load balancer, under the context of service principal created above. 
> *Since the az cli doesn't have any means to create the AKS cluster without load balancer, using the ARM template.*

The parameters.json & template.json files can be found [here](https://github.com/abhinabsarkar/aks/tree/master/src/aks-agic)
```bash
rgName="rg-aksAgicPmi"
deploymentName="dep-aksAgicPmi"
# Get the service principal credentials
appId=$(jq -r ".appId" auth.json)
password=$(jq -r ".password" auth.json)
spPrincipalId=$(az ad sp show --id $appId --query objectId --output tsv)
# Update manually the parameters.json with below values
# principalId = <value_of_spPrincipalId>
# servicePrincipalClientId = <value_of_appId> 
# servicePrincipalClientSecret = <value_of_password>

# Create an AKS cluster with no load balancer
az group deployment create -g $rgName -n $deploymentName --template-file template.json --parameters parameters.json --verbose
# Once the deployment finished, download the deployment output into a file named deployment-outputs.json
az group deployment show -g $rgName -n $deploymentName --query "properties.outputs" -o json > deployment-outputs.json
```
> In case of error with deployment, use the switch --debug

Resources created using the template in the *rg-aksAgicPmi* resource group  
> Note that it doesn't have a load balancer / application gateway yet  

![Alt text](/images/rg-aksAgicPmi.jpg)

Resources created in the node resource group  
![Alt text](/images/node-rg-aksAgicPmi.jpg)

* Create Application Gateway in the resource group

  An application gateway is a dedicated deployment in your virtual network. Within your virtual network, a dedicated subnet is required for the application gateway. You can have multiple instances of a given application gateway deployment in a subnet. You can also deploy other application gateways in the subnet. But you can't deploy any other resource in the application gateway subnet.
```bash
# Get VNet name for creating application gateway subnet
vnetName=$(jq -r ".vnetName.value" deployment-outputs.json)
# Application gateway will have its own dedicated subnet within virtual network
appGwySubnet="ags-aksAgicPmi"
# create application gateway subnet
az network vnet subnet create \
  --name $appGwySubnet\
  --resource-group $rgName \
  --vnet-name $vnetName \
  --address-prefix 10.1.0.0/16 \
  --verbose

# Set the variables for application gateway
appGwyName="ag-aksAgicPmi"
location="eastus2"
applicationGatewayPublicIpName=$(jq -r ".applicationGatewayPublicIpName.value" deployment-outputs.json)
# Create the application gateway
az network application-gateway create \
  --name $appGwyName \
  --location $location \
  --resource-group $rgName \
  --sku WAF_v2 \
  --http-settings-cookie-based-affinity disabled \
  --public-ip-address $applicationGatewayPublicIpName \
  --vnet-name $vnetName \
  --subnet $appGwySubnet \
  --tags Identifier=abs-aksAgicPmi \
  --verbose
```

* Create a user-assigned managed identity in the **resource group** where Application Gateway resides

```bash
# To create a user-assigned managed identity, your account needs the Managed Identity Contributor role assignment
# Create a managed identity
identityName="mi-appGwy"
az identity create --resource-group $rgName --name $identityName --tags Identifier=abs-aksAgicPmi
```

## Assign access to the AKS Service Principal & User-Assigned Managed Identity 
### Role assignment is done by the system admins i.e. subscription owner

1. AKS Service Principal requires 'Managed Identity Operator' access on Controller identity
```bash
# Get resource ID of the user-assigned identity
identityId=$(az identity show --resource-group $rgName --name $identityName --query id --output tsv)
# Get the principal id of the service principal
appId=$(jq -r ".appId" auth.json)
spPrincipalId=$(az ad sp show --id $appId --query objectId --output tsv)
# Assign the role 'Managed Identity Operator' to service principal 'sp-aksmi' scoped to the Managed Identity created above
az role assignment create --assignee $spPrincipalId --scope $identityId --role 'Managed Identity Operator'
# Check the role assignment
az role assignment list --scope $identityId -o table
```

2. AGIC Identity requires 'Contributor' access on Application Gateway and 'Reader' access on Application Gateway's Resource Group

> Assigning contributor access to the user-assigned managed identity on the resource group, doesn't give contributor access to the Application Gateway

```bash
# Get resource ID of the resource group 
rgId=$(az group show -n $rgName --query id -o tsv)
# Get the principal id of the user-assigned identity
uiID=$(az identity show --resource-group $rgName --name $identityName --query principalId --output tsv)
# Assign the role 'reader' to the Managed Identity created above scoped to the resource group 'rg-aksAgicPmi'
az role assignment create --assignee $uiID --scope $rgId --role 'reader'
#az role assignment create --assignee-object-id $uiID --assignee-principal-type 'ServicePrincipal' --scope $rgId --role 'reader'
# Check the role assignment
az role assignment list --scope $rgId -o table

# Get resource ID of the application gateway
appGwyId=$(az network application-gateway show --resource-group $rgName -n $appGwyName --query id --output tsv)
# Get the principal id of the user-assigned identity
uiID=$(az identity show --resource-group $rgName --name $identityName --query principalId --output tsv)
# Assign the role 'contributor' to the Managed Identity created above scoped to the Application Gateway
az role assignment create --assignee $uiID --scope $appGwyId --role 'contributor'
# Check the role assignment
az role assignment list --scope $appGwyId -o table
```

## Set up Application Gateway Ingress Controller
### Creating kubernetes resources
* Create Pod Managed Identity
[AAD Pod Identity](https://github.com/Azure/aad-pod-identity) will add the following components to your Kubernetes cluster:
1. Kubernetes [CRDs](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/): AzureIdentity, AzureAssignedIdentity, AzureIdentityBinding
2. [Managed Identity Controller (MIC)](https://github.com/Azure/aad-pod-identity#managed-identity-controllermic) component
3. [Node Managed Identity (NMI)](https://github.com/Azure/aad-pod-identity#node-managed-identitynmi) component
```bash
# use the deployment-outputs.json created after deployment to get the cluster name and resource group name
aksClusterName=$(jq -r ".aksClusterName.value" deployment-outputs.json)
# Get the aks credentials
az aks get-credentials --resource-group $rgName --name $aksClusterName
```

```bash
# Install AAD Pod Identity to RBAC enabled AKS cluster
# Use AAD Pod Identity v1.5.5 when using AGIC <= 1.2.0-rc1 issue: https://github.com/Azure/application-gateway-kubernetes-ingress/issues/828
kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/v1.5.5/deploy/infra/deployment-rbac.yaml

# To install from AAD Pod identity master branch, use the following
kubectl create -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml
```

It will create the below pods
```bash
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
pod/mic-76cd857787-cl949   1/1     Running   0          67s
pod/mic-76cd857787-srjk9   1/1     Running   0          67s
pod/nmi-dqvrj              1/1     Running   0          67s
```

* Create the Application Gateway Ingress Controller
```bash
# Add the AGIC Helm repository
helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
helm repo update
# Download helm-config.yaml, which will configure AGIC
wget https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/sample-helm-config.yaml -O helm-config.yaml
# Get the user assigned identity details - id & client id
identityResourceId=$(az identity show --resource-group $rgName --name $identityName --query id --output tsv)
identityClientId=$(az identity show --resource-group $rgName --name $identityName --query clientId --output tsv)
# Edit the newly downloaded helm-config.yaml and update the below sections
sed -i "s|<subscriptionId>|${subscriptionId}|g" helm-config.yaml
sed -i "s|<resourceGroupName>|${rgName}|g" helm-config.yaml
sed -i "s|<applicationGatewayName>|${appGwyName}|g" helm-config.yaml
sed -i "s|<identityResourceId>|${identityResourceId}|g" helm-config.yaml
sed -i "s|<identityClientId>|${identityClientId}|g" helm-config.yaml
sed -i "s|enabled: false|enabled: true|g" helm-config.yaml
```
Install the Application Gateway ingress controller package in the AKS cluster
```bash
# Install the Application Gateway ingress controller package in the AKS cluster
helm install ingress-azure -f helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure --version 1.0.0
# Note: Use at least version 1.2.0-rc1, e.g. --version 1.2.0-rc1, when installing on k8s version >= 1.16
```
When the ingress controller is up and running, it will show up as shown below
```bash
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
ingress-azure-db7567987-vc748   1/1     Running   0          53s
mic-f7bdd4f9b-pmkfs             1/1     Running   0          11m
mic-f7bdd4f9b-xw8bh             1/1     Running   0          11m
nmi-xhmmg                       1/1     Running   0          11m
```

## Debugging steps
If the ingress pod fails to start, try the following steps to get the logs & debug
* Bring up kubernetes dashboard
```bash
# To access an RBAC enabled kubernetes dahsnoard
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
# Start the kubernetes dashboard
az aks browse --resource-group $rgName --name $aksClusterName
# Browse the dashboard
'http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/#!/overview?namespace=default'
```

If dashboard can't be enabled, use the cli commands to troubleshoot
```bash
# Check status
kubectl get svc,pods --all-namespaces
kubectl get events
# Get into the container
docker exec -it <container name> <command>
docker exec -it <container name> /bin/bash
# Kubernetes pod events
kubectl describe pod <pod-which-is-crashing>
# Kubernetes logs 
kubectl logs <pod-which-is-crashing>
```

* To switch to a different version of Application Gateway Ingress Controller
```bash
helm list
helm delete <chart_name>
# To get the pre-release versions & deploying it
helm search repo ingress-azure --versions --devel
helm install ingress-azure -f helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure --version 1.2.0-rc1
helm install ingress-azure -f helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure --version 1.0.1-rc1
```

## Run sample applications
Deploy two sample applications
1. aspnetapp - The details for the app can be found [here](https://github.com/dotnet/dotnet-docker/tree/master/samples/aspnetapp). Refer the application deployment yaml [here](https://github.com/abhinabsarkar/aks/tree/master/src/aks-agic/aspnetapp.yaml)  
```bash
kubectl create -f aspnetapp.yaml
# get the running pods and services
kubectl get pods,svc -o wide
NAME                  READY   STATUS    RESTARTS   AGE     IP          NODE                        
pod/aspnetapp-69fd4   1/1     Running   0          2m43s   10.0.0.10   aks-agentpool-33245669-vmss0
pod/aspnetapp-69fd4   1/1     Running   0          2m43s   10.0.0.29   aks-agentpool-33245669-vmss0
pod/aspnetapp-69fd4   1/1     Running   0          2m43s   10.0.0.17   aks-agentpool-33245669-vmss0
pod/ingress-azure-d   1/1     Running   0          39m     10.0.0.19   aks-agentpool-33245669-vmss0
pod/mic-f7bdd4f9b-9   1/1     Running   0          40m     10.0.0.9    aks-agentpool-33245669-vmss0
pod/mic-f7bdd4f9b-m   1/1     Running   0          40m     10.0.0.28   aks-agentpool-33245669-vmss0
pod/nmi-tqjbc         1/1     Running   0          40m     10.0.0.4    aks-agentpool-33245669-vmss0

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE    SELECTOR
service/aspnetapp    ClusterIP   10.2.73.29   <none>        80/TCP    2m7s   app=aspnetapp
service/kubernetes   ClusterIP   10.2.0.1     <none>        443/TCP   53m    <none>
```

The first application can be browsed by using the public ip address of the AKS cluster. 
```bash
az network public-ip list -g $rgName -o table
```

![Alt text](/images/aspnetapp.jpg)

2. abs-hello-csharp-app - Docker hub image & application code can be found [here](https://github.com/abhinabsarkar/hellocsharp). The second application shows the path based routing done at the ingress controller. Refer the application deployment yaml [here](https://github.com/abhinabsarkar/aks/tree/master/src/aks-agic/abs-hello-csharp-app.yaml)  
```bash
kubectl create -f abs-hello-csharp-app.yaml
```

The application is available at the same public IP address but exposed on a different route. It can be accessed by going to http://<public_ip>/abs

![Alt text](/images/abs-charp-hello.jpg)

## Clean up resources
Delete the resource group & the service principal
```bash
az group delete -n $rgName --yes --no-wait
az ad sp delete --id $spPrincipalId
```
