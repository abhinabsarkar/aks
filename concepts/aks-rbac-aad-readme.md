# Azure Kubernetes Service (AKS) & Role-Based Access Control (RBAC) using Azure Active Directory (AAD)

AKS clusters integrated with Azure AD provides role-based access control to manage resources and services. With Azure AD, on-premise identities can be integrated into AKS clusters to provide a single source for account management and security. This allows the admin to grant users or groups access to Kubernetes resources within a namespace or across the cluster.

## Kubernetes accounts
Every request made to the Kubernetes API, be it kubectl on a workstation, to kubelets on nodes, to members of the control plane server must be authenticated. These API requests are made under the context of an account. 

Access to a kubernetes cluster can be granted using two types of accounts:
* **Service Account** 
    * managed by Kubernetes
    * created automatically by the API server or manually through API calls
    * tied to namepaces
    * credentials for service accounts are stored as Kubernetes Secrets, which are mounted into authorized pods to communicate with the Kubernetes API Server
* **User Account**
    * managed by an external entity, for AKS, it is Azure Active Directory (AAD)
    * created by Kubernetes RBAC in conjunction with Azure AD-integration
        * Add a user or group to Azure AD
        * Create a Kubernetes Role for a namespace with appropriate permissions or create a Cluster Role
        * Create a RoleBinding that binds the Azure AD user or group to the Role
    * tied to a namespace or cluster
    * credentials are stored in the external identity provider

## AKS & AAD integration
With Azure AD-integrated AKS clusters, admins can grant AAD users or groups, access to Kubernetes resources within a namespace or across the cluster. This can be accomplished by Azure role-based access control (RBAC) in conjunction with Kubernetes RBAC.

An AKS cluster actually has two types of credentials for calling the Kubernetes API server: 
* cluster admin - full access to the AKS cluster
* cluster user - no permissions by default on the AKS cluster

The above two roles are assigned to an Azure AD user by using the Azure RBAC Roles mentioned below:
* **Azure Kubernetes Service Cluster Admin Role** - It has permission to download the cluster admin credentials. Only cluster admin should be assigned this role. Azure Contributor Role has this in-built role added to it, that's why all Azure AD users with **Contributor Role** are cluster admins.
* **Azure Kubernetes Service Cluster User Role** - It has permission to download the cluster user credentials. Non-admin users can be assigned to this role. This role does not give any particular permissions on Kubernetes resources inside the cluster — it just allows a user to connect to the API server. Since the Azure **Reader Role** is a superset of this role, all Azure AD users with the Reader role will have this in-built role added. Kubernetes permissions using RBAC (Roles, RoleBindings & ClusterRoles for cases like installing Couchbase DB) will be assigned to these Azure AD users.

When the below command is executed by cluster admin, it downloads the cluster admin credentials and saves them into the kubeconfig file.
```bash
az aks get-credentials --admin
```
The cluster administrator can use this kubeconfig to create Roles and RoleBindings, and assign them to the user.

Lets say an Azure AD user "Engineering User" runs the below command to obtain a kubectl configuration context 
```cmd
az aks get-credentials
```
When a user then interacts with the AKS cluster with kubectl, he is prompted to sign in with his Azure AD credentials. This approach provides a single source for user account management and password credentials. The user can only access the resources as defined by the cluster administrator.

![Alt text](/images/aad-integration.jpg)

## Authentication mechanism
Azure AD authentication in AKS clusters uses [OpenID Connect](https://docs.microsoft.com/en-us/azure/active-directory/develop/v1-protocols-openid-connect-code), an identity layer built on top of the [OAuth 2.0 protocol](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-app-types). The protocol’s main extension of OAuth2 is an additional field returned with the access token called an ID Token. This token is a JSON Web Token (JWT) with well known fields, such as a user’s email, signed by the server. 

![Alt text](/images/sequence-diagram.jpg)

Authentication steps
1. Login to Azure AD
2. Azure AD will provide the user with an access_token, id_token and a refresh_token
3. When using kubectl, the user will user id_token with the --token flag or add it directly to the kubeconfig by using "az aks get-credentials" command
4. kubectl sends the id_token in a header called Authorization to the API server
5. The API server will make sure the JWT signature is valid by checking against the certificate named in the configuration
6. Check to make sure the id_token hasn’t expired
7. Make sure the user is authorized
8. Once authorized the API server returns a response to kubectl
9. kubectl provides feedback to the user

To verify the authentication tokens obtained from Azure AD through OpenID Connect, AKS clusters use [Kubernetes Webhook Token Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#webhook-token-authentication).

## Kubernetes role-based access control (RBAC)
Kubernetes provide granular control of access to resources in the cluster using [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/). This control mechanism lets you assign Azure users, or groups of users, permission to do things like create or modify resources, or view logs from running application workloads. These permissions can be scoped to a single namespace, or granted across the entire AKS cluster. With Kubernetes RBAC, you create *Roles* to define permissions, and then assign those Roles to users with *RoleBindings*.

As an example, you can create a Role that grants full access to resources in the namespace named finance-app, as shown in the following example YAML manifest:
```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
    name: finance-app-full-access-role
    namespace: finance-app
rules:
- apiGroups: [""]
    resources: ["*"]
    verbs: ["*"]
```
A RoleBinding is then created that binds the Azure AD user developer1@contoso.com to the RoleBinding, as shown in the following YAML manifest:
```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
    name: finance-app-full-access-role-binding
    namespace: finance-app
subjects:
- kind: User
    name: developer1@contoso.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
    kind: Role
    name: finance-app-full-access-role
    apiGroup: rbac.authorization.k8s.io        
```    
When developer1@contoso.com is authenticated against the AKS cluster, they have full permissions to resources in the finance-app namespace.

![Alt text](/images/cluster-level-authentication-flow.jpg)

Authentication flow
1. Developer authenticates with Azure AD.
2. The Azure AD token issuance endpoint issues the access token.
3. The developer performs an action using the Azure AD token, such as kubectl create pod
4. Kubernetes validates the token with Azure Active Directory and fetches the developer's group memberships.
5. Kubernetes role-based access control (RBAC) and cluster policies are applied.
6. Developer's request is successful or not based on previous validation of Azure AD group membership and Kubernetes RBAC and policies.