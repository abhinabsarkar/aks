# AKS integration with Azure AD & RBAC - Demo
Login to Azure subscription using a Service Principal or an user account. In this case, I am using user account to login to the subscription which is having owner permission. 

Later we will switch to a different account to change context & test the permissions.

## Create AKS cluster
```bash
# Create resource group
rgName=rg-abhi-aks
location=canadacentral
az group create -g $rgName -l $location --tags "RG-Name=Abhi"
# Create an AKS cluster
az aks create --resource-group $rgName --name aks-abs-demo1 \
    --node-count 3 --generate-ssh-keys \
    --enable-aad --enable-azure-rbac \
    --verbose
```
AKS cluster with managed Azure Active Directory & RBAC is created. But you don't have any permissions on this cluster. 

## Validate permissions on the AKS cluster
```bash
# Get the AKS cluster user credentials to connect from local machine
az aks get-credentials --resource-group $rgName --name aks-abs-demo1 --overwrite-existing
# The above command only gets the access credentials & by default merges the .kube/config file so kubectl can use them
# If you use a service principal or a user with no RBAC permissions, the above command will return an error

# Try to access pods for the current logged-in user
kubectl get pods
# The above will return error from server (forbidden)
# The user doesn't have any permissions on the cluster
```

## Grant AKS RBAC cluster admin to the logged in user 
```bash
# To designate the user as cluster admin, assign the Azure Kubernetes Service RBAC Cluster Admin role
# Get the object Id of the logged in user
currentUserObjectId=$(az ad signed-in-user show --query objectId -o tsv)
# Get Azure AKS Cluster Id
aksClusterId=$(az aks show -g $rgName --name aks-abs-demo1 --query id -o tsv)
# Assign the AKS RBAC role
az role assignment create \
  --assignee $currentUserObjectId \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope $aksClusterId
# The role assignment takes some time. Check if the role assignment is complete
az role assignment list --assignee $currentUserObjectId --scope $aksClusterId -o table
# Once the role assigned shows up, you can get the AKS credentials
az aks get-credentials --resource-group $rgName --name aks-abs-demo1 --overwrite-existing
# Use kubectl to access the pods & it will work
kubectl get pods
```
Now the signed in user can also view the k8s resources in the Azure Portal.

![alt txt](/images/k8s-resources-portal.png)

## Grant permissions to the cluster to a Service Principal using Azure RBAC
```bash
# Get Azure AKS Cluster Id
aksClusterId=$(az aks show -g $rgName --name aks-abs-demo1 --query id -o tsv)

# Create an Azure AD group
devAADGroup=$(az ad group create --display-name dev-aad-group --mail-nickname dev-aad-group --query objectId -o tsv)

# Assign AKS RBAC role to the AAD group
az role assignment create \
  --assignee $devAADGroup --scope $aksClusterId	\
  --role "Azure Kubernetes Service Cluster User Role"  

# Create an SP or a user. In this case, creating SP. Store the credentials generated as output
az ad sp create-for-rbac -n sp-aks-cicd
# Get the objectId using the app Id, The appId is in the output of previous command
appId=
spObjectId=$(az ad sp show --id $appId --query "objectId" -o tsv)
# Add the SP to the AAD group
az ad group member add --group $devAADGroup --member-id $spObjectId

# The service principal can authenticate to the cluster, but it doesn't have any permissions
# Use the built-in AKS RBAC role to grant reader permissions on the cluster
# Assign AKS RBAC Reader role to the AAD group
az role assignment create \
  --assignee $devAADGroup --scope $aksClusterId	\
  --role "Azure Kubernetes Service RBAC Reader"
# The role assignment takes some time. Check if the role assignment is complete
az role assignment list --assignee $devAADGroup --scope $aksClusterId -o table
# Once the role shows up, you can login using service principal to validate the permissions 
``` 

## Validate permissions for Service Principal on AKS cluster
**Interactive login** - Once you have assigned the necessary access rights to the user or group, a user can login by first obtaining credentials using `az aks get-credentials`. However, when a command such as `kubectl get pods` is run, the user will need to authenticate to Azure AD by opening a browser and entering the code displayed. When the code is entered, and the user has the necessary role to run the command, the output will appear.

**Non-Interactive login** - There are some non-interactive scenarios, such as continuous integration pipelines, that aren't currently available with kubectl. You can use [kubelogin](https://github.com/Azure/kubelogin) to access the cluster with non-interactive service principal sign-in. 
* [Non-interactive sign in with kubelogin - Microsoft](https://docs.microsoft.com/en-us/azure/aks/managed-aad#non-interactive-sign-in-with-kubelogin)
* [Kubelogin in pipeline](https://blog.baeke.info/2021/06/03/a-quick-look-at-azure-kubelogin/)

```bash
# Open a new bash shell & login using service principal sp-aks-cicd
az login --service-principal -u $appId -p $pwd -t $tenant

clusterName=aks-abs-demo1
# Get the cluster credentials & export to kubeconfig file in the local folder
az aks get-credentials -g $rgName \
    --name $clusterName --overwrite-existing \
    --file .kubeconfig-${clusterName}
# Use Kubelogin to convert your kubeconfig
export KUBECONFIG=$(pwd)/.kubeconfig-${clusterName}
kubelogin convert-kubeconfig -l spn
export AAD_SERVICE_PRINCIPAL_CLIENT_ID=$appId
export AAD_SERVICE_PRINCIPAL_CLIENT_SECRET=$pwd
# run kubectl to check if you can access pods in all namespaces 
kubectl get pods --all-namespaces
```

## Grant permissions using k8s RBAC custom role to the SP
So far we have assigned the permissions following permissions to the AAD Group:
* Azure Kubernetes Service Cluster User Role
* Azure Kubernetes Service RBAC Reader

Now we are going to assign a k8s RBAC role to the AAD group to manage deployments.

Switch to bash shell which is having access to the cluster under the context of user with AKS RBAC admin
```bash
# Verify that you can create namespaces
kubectl auth can-i create namespaces --all-namespaces
# Create Namespaces dev and qa
kubectl create namespace dev
kubectl create namespace qa
```

Create a custom role for deployment using the file [rbac-deployment-role.yaml](/src/rbac-deployment-role.yaml)

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: dev
  name: deployment-role
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["deployments", "replicasets", "pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```
```bash
# create role
kubectl apply -f rbac-deployment-role.yaml -n dev
```

Create rolebinding for the above role & assign it to the AAD group.
```bash
# Get the AAD group
devAADGroup=$(az ad group create --display-name dev-aad-group --mail-nickname dev-aad-group --query objectId -o tsv)
``` 
```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: deployment-rolebinding
  namespace: dev
subjects:
- kind: Group
  name: <AADGroup-object-id>
  apiGroup: ""
roleRef:
  kind: Role
  name: deployment-role
  apiGroup: ""
```

```bash
# Replace the AAD group object id in the rbac-deployment-rolebinding.yaml
# Apply role binding
kubectl apply -f rbac-deployment-rolebinding.yaml -n dev
```
The k8s RBAC role assignment is complete

## Validate k8s RBAC role assignment
Switch to the bash shell which is accessing the cluster under the context of service principal sp-aks-cicd. 

```bash
# Validate the permissions on dev namespace
kubectl auth can-i create deployment -n dev
# You should get below response
yes
# Validate the permissions on qa namespace
kubectl auth can-i create deployment -n qa
# You should get the below response
no - User does not have access to the resource in Azure. Update role assignment to allow access.

# Deploy to dev namespace
kubectl create deployment nginx --image=nginx -n dev
# Access application in dev namespace
kubectl get pods -n dev

# Try deploying in qa namespace
kubectl create deployment nginx --image=nginx -n qa
# You should get a failed response
error: failed to create deployment: deployments.apps is forbidden:
```

## Configure RBAC in K8S cluster – AKS + Istio
If you have Istio Service Mesh on your cluster, then you my have to create another custom role for deployment/management of Istio. o	Adding Istio related RBAC in the same custom role which would be used for AKS may not be ideal. Will all applications require all the rich features of Istio? A good approach would be to create a custom deployment role for k8s APIs & create another set of RBAC roles for Istio. Assign the k8s & Istio custom roles based on the permissions required for the respective deployments. 

```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: dev
  name: istio-edit-role
rules:
- apiGroups: ["config.istio.io", "networking.istio.io", "authentication.istio.io"]
  resources: ["*"]
  verbs: ["*"]
```
Refer the below links
* https://rancher.com/docs/rancher/v2.5/en/istio/rbac/ - RBAC based on CRD permissions
* https://docs.bitnami.com/tutorials/configure-rbac-in-your-kubernetes-cluster/#step-3-create-the-role-for-managing-deployments 
* https://stackoverflow.com/questions/54700745/what-roles-should-be-created-used-for-deploying-a-service-that-uses-istio 
* https://github.com/IBM/istio101/blob/master/presentation/scripts/install/kubernetes/istio-auth.yaml 
