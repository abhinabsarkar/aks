# Local accounts in AKS & Audit logs
Usually when you authenticate to an Azure AD enabled AKS cluster, it uses OAuth leveraging the Azure AD authentication process to reduce the risk of a misplaced kubeconfig file.

However, if you use `az aks get-credentials` command passing `--admin` to that command, instead of using OAuth, it adds a client certificate file to kubeconfig.

Client certificate authentication in Kubernetes is a problem because there is no way to revoke a credential once it’s issued. 

![alt txt](/images/aks-client-cert.jpg)

The way Kubernetes client certificate authentication works, the `CN` field is considered the username and the `O` field is the group the user belongs to, so this is logging in with a username of `masterclient` and a group of `system:masters`.

## <ins>*Issues:*</ins>
1. It logs with a username as `masterclient` for all the users logging as admin, hence it is not auditable.
2. `System:masters` is a group which is hardcoded into the Kubernetes API server source code as having unrestricted rights to the Kubernetes API server. The local cluster admin account is added by default, giving a backdoor option.

This can be seen by running the below query in Log Analytics workspace for an AKS cluster created using `az aks update -g <rg-name> -n <cluster-name> --enable-local` which has Audit Logs enabled within the Diagnostic settings.

```kql
AzureDiagnostics
| where Category == "kube-audit"
| extend log_j=parse_json(log_s) 
| extend username=log_j.user.username
| where username in ("masterclient")
```
![alt txt](/images/masterclient.jpg)

## <ins>*Solution: Disable local accounts in AKS*</ins>
When deploying an AKS Cluster, local accounts are enabled by default. Even when enabling RBAC or Azure Active Directory integration, `--admin` access still exists, essentially as a non-auditable backdoor option. With this in mind, AKS offers users the ability to disable local accounts via a flag, `disable-local-accounts`. 

```bash
# When creating a new AKS cluster
az aks create -g <resource-group> -n <cluster-name> --enable-aad --aad-admin-group-object-ids <aad-group-id> --disable-local-accounts

# Disable local accounts on an existing cluster
az aks update -g <resource-group> -n <cluster-name> --enable-aad --aad-admin-group-object-ids <aad-group-id> --disable-local-accounts
```

The output confirms the local account is disabled.
```json
"properties": {
    ...
    "disableLocalAccounts": true,
    ...
}
```

Once the above steps are taken, attempt to get admin credentials will fail with an error message indicating the feature is preventing access:

```bash
az aks get-credentials --resource-group <resource-group> --name <cluster-name> --admin

Operation failed with status: 'Bad Request'. Details: Getting static credential is not allowed because this cluster is set to disable local accounts.
```

For a cluster which has local accounts disabled, run the below query on Log Analytics workspace.
```kql
AzureDiagnostics
| where Category == "kube-audit"
| extend log_j=parse_json(log_s) 
| extend username=log_j.user.username
| where username contains "microsoft.com"
```

![alt txt](/images/user-auditlogs.jpg)

## Use Conditional Access with Azure AD and AKS
When integrating Azure AD with your AKS cluster, you can also use [Conditional Access](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/overview) to control access to your cluster. Refer [AKS conditional access using Azure AD](https://docs.microsoft.com/en-us/azure/aks/managed-aad#use-conditional-access-with-azure-ad-and-aks)

## References
* [Disable local accounts in AKS](https://docs.microsoft.com/en-us/azure/aks/managed-aad#disable-local-accounts)
* [Enable audit logging for Azure resources](https://docs.microsoft.com/en-us/security/benchmark/azure/baselines/aks-security-baseline#23-enable-audit-logging-for-azure-resources)
* [Azure AKS Audit logs view](https://stackoverflow.com/questions/60589131/azure-aks-audit-logs-view)
* [Identity, Authentication and Authorization for Azure Kubernetes Service — Detailed](https://medium.com/microsoftazure/azure-kubernetes-service-aks-authentication-and-authorization-between-azure-rbac-and-k8s-rbac-eab57ab8345d)
* [Privilege Escalation in AKS Clusters](https://www.securesystems.de/blog/privilege-escalation-in-aks-clusters/)
* [system:masters in Kubernetes](https://blog.aquasec.com/kubernetes-authorization)