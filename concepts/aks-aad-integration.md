# Integrate Azure Active Directory (AAD) with Azure Kubernetes Service (AKS)
Azure Kubernetes Service (AKS) can be configured to use Azure Active Directory (Azure AD) for user authentication. Cluster administrators can configure Kubernetes role-based access control (RBAC) based on a user's identity or directory group membership.
> **Azure AD can only be enabled when you create a new RBAC-enabled cluster. You can't enable Azure AD on an existing AKS cluster.**

## Authentication
Azure AD authentication is provided to AKS clusters that have OpenID Connect. OpenID Connect is an identity layer built on top of the OAuth 2.0 protocol. Refer this [link](/concepts/aks-rbac-aad-readme.md#authentication-mechanism) for details. 

To provide Azure AD authentication for an AKS cluster, two Azure AD applications (Service Principals) are created. The first application is a server component that provides user authentication. The second application is a client component that's used when you're prompted by the CLI for authentication. This client application uses the server application for the actual authentication of the credentials provided by the client. The steps to delegate permissions for each application must be completed by an Azure tenant administrator.

### 1. Create the server application (Service Principal) - can be done from Azure Portal too
To integrate with AKS, you create and use an Azure AD application that acts as an endpoint for the identity requests. The first Azure AD application you need gets Azure AD group membership for a user.

Create the server application component
```bash
# Create the Azure AD application
az ad app create --display-name "AKSAzureADServer" --identifier-uris "https://aksazureadserver" --query appId -o tsv
```
Update the group membership claims
```bash
# Update the application group memebership claims
az ad app update --id <Server Application ID> --set groupMembershipClaims=All
```
Create a service principal for the server app & get the service principal secret
```bash
# Create a service principal for the Azure AD application
az ad sp create --id $<Server Application ID>

# Get the service principal secret
az ad sp credential reset --name <Server Application ID>  --credential-description "AKSPassword" --query password -o tsv
```
Assign the permissions required by Azure AD to perform the following actions:
* Read directory data
* Sign in and read user profile
```bash
az ad app permission add --id <Server Application ID> --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role
```

Finally, grant the permissions assigned in the previous step for the server application. Also add permissions for Azure AD application to request information that may otherwise require administrative consent.
```bash
az ad app permission grant --id <Server Application ID> --api 00000003-0000-0000-c000-000000000000
az ad app permission admin-consent --id  <Server Application ID>
```

### 2. Create the client application (Service Principal) - can be done from Azure Portal too
The second Azure AD application is used when a user logs to the AKS cluster with the Kubernetes CLI (kubectl). This client application takes the authentication request from the user and verifies their credentials and permissions.

Create the Azure AD app for the client component
```bash
# Create the Azure AD client application
az ad app create --display-name "AKSAzureADClient" --native-app --reply-urls "https://aksazureadclient" --query appId -o tsv
```
Create a service principal for the client application
```bash
az ad sp create --id <Client Application Id>
```
Get the oAuth2 ID <OAuth Permission Id> for the server app to allow the authentication flow between the two app component
```bash
az ad app show --id <Server Application ID> --query "oauth2Permissions[0].id" -o tsv
```
Add the permissions for the client application and server application components to use the oAuth2 communication flow. Then, grant permissions for the client application to communication with the server application.
```bash
az ad app permission add --id <Client Application Id> --api <Server Application ID> --api-permissions <OAuth Permission Id>=Scope
az ad app permission grant --id <Client Application Id> --api <Server Application ID>
```
> The complete sample script can be found [here](https://github.com/Azure-Samples/azure-cli-samples/blob/master/aks/azure-ad-integration/azure-ad-integration.sh)

## Deploy the AKS cluster
Create a resource group for the cluster
```bash
az group create --name rg-aks-test --location EastUS --verbose
```
Create the AKS cluster
```bash
az aks create --resource-group rg-aks-test --name myAKSCluster --generate-ssh-keys --aad-server-app-id <Server Application ID> --aad-server-app-secret <Server Application Secret> --aad-client-app-id <Client Application Id> --aad-tenant-id <Tenant ID> --verbose
```
Finally, get the cluster admin credentials
```bash
az aks get-credentials --resource-group rg-aks-test --name myAKSCluster --admin --verbose
```

Before adding an AAD user, check access to the cluster as admin
```bash
# Check whether admin user can get pods
kubectl get pods
# Create namespace as admin
kubectl create namespace abs
kubectl get namespaces --show-labels
# Create a deployment with replica size as 2 that is running the pod called snowflake with a basic container that just serves the hostname
kubectl run snowflake --image=k8s.gcr.io/serve_hostname --replicas=2 --namespace abs
kubectl get deployment
kubectl get pods -l run=snowflake
```

## Add an authorized Azure AD user to the AKS cluster
The Azure AD user to be given access to the AKS cluster can be on the same Azure AD tenant or in a different Azure AD tenant. The Azure AD user list can found by running the below command
```bash
# Get the object id for abhinab@email.com
az ad user list
# The object id can be verified by running the below command
az ad user show --id <object id> --query objectId -o tsv
```

Create a **Role** say 'pod-reader' for the namespace 'abs' created above via file 'pod-reader-abs.yaml'
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: abs
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

Apply the Role using kubectl
```bash
kubectl apply -f rbac-role-podreader-abs.yaml
```
Create a **RoleBinding** file 'rbac-aad-podreader-abs.yaml' which gives 'pod-reader' access to the AAD user 'abhinab@email.com' with the object id, say 'xxxxxx-yyyyy-zzzzz' on the 'abs' namespace in the AKS cluster 'myAKScluster'
```yaml
apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "user" to read pods in the "abs" namespace.
kind: RoleBinding
metadata:
  name: read-pods
  namespace: abs
subjects:
- kind: User
  name: xxxxxx-yyyyy-zzzzz # Object id
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```
Apply the RoleBinding by using the kubectl apply command as shown in the following example:
```bash
kubectl apply -f rbac-aad-podreader-abs.yaml
```

A RoleBinding can also be created for all members of an Azure AD group. Azure AD groups are specified by using the group object ID. Refer [this](https://docs.microsoft.com/en-us/azure/aks/azure-ad-rbac?toc=https%3A%2F%2Fdocs.microsoft.com%2Fen-us%2Fazure%2Faks%2FTOC.json&bc=https%3A%2F%2Fdocs.microsoft.com%2Fen-us%2Fazure%2Fbread%2Ftoc.json)

To access the cluster as an Azure AD user, pull the context in kubectk config for the non-admin user by using the az aks get-credentials command.
```bash
az aks get-credentials --resource-group rg-aks-test --name myAKSCluster
```

Try running the kubectl command now as a non-admin user
```bash
# Get the pods in the abs namespace as user 'abhinab@email.com'
kubectl get pods --namespace abs
```

After you run the kubectl command, you'll be prompted to authenticate by using Azure. Follow the on-screen instructions to finish the process, as shown in the following example:
![Alt text](/images/kubectl-auth-aks.jpg)

After successful authentication, it will list the pods.
![Alt text](/images/success-auth.jpg)

If the user tries to access pods in a different namespace, then it will deny access
![Alt text](/images/failed-auth.jpg)
