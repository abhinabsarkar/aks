# Azure Key Vault Provider for Secrets Store CSI Driver in an AKS cluster

Azure Key Vault secrets provider extension allows you to get secret contents stored in an Azure Key Vault instance and uses the [Secrets Store CSI driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver) interface to mount them into Kubernetes pods of Azure Kubernetes clusters, thereby reducing the exposure of secrets to the minimum. 

## How does this work?
Once the extension is installed, it deploys Secrets Store CSI driver and AKV secrets provider as daemon sets. The application teams then create their custom resource `SecretProviderClass`, referencing the AKV instance and its contents. Further, the application teams reference this SecretProviderClass object in application pod manifests. 

On application pod start and restart, the Secrets Store CSI driver communicates with the Azure Key Vault secrets provider using `gRPC` to retrieve the secret content from the Azure Key Vault specified in the `SecretProviderClass` custom resource. Then the volume is mounted in the pod as `tmpfs` and the secret contents are written to the volume. On pod delete, the corresponding volume is cleaned up and deleted.

![alt txt](/images/CSI-driver-Interface.png)

## Steps to configure AKV provider for Secrets Store CSI Driver in an AKS cluster
### Create resources in Azure
```bash
# Create an AKS cluster
az aks create --resource-group rg-aks-demo1 --name aks-demo1 --node-count 1 --generate-ssh-keys --verbose
# Upgrade an existing AKS cluster with Azure Key Vault Provider for Secrets Store CSI Driver support
az aks enable-addons --addons azure-keyvault-secrets-provider --name aks-demo1 --resource-group rg-aks-demo1
# Verify the Azure Key Vault Provider for Secrets Store CSI Driver installation
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'

# Create an Azure key vault
az keyvault create -n kv-aks-demo1 -g rg-aks-demo1 -l canadacentral
# Store the secret
az keyvault secret set --vault-name kv-aks-demo1 -n redis-secret --value tC2EcVJf9sdsfVQbZpK8Rzu7UC4bUNtBOAzCaFjRSMs=
```

### Provide an identity to access the Azure key vault
```bash
# Get the user-assigned managed identity for the AKS cluster
identityId=$(az aks show -g rg-aks-demo1 -n aks-demo1 --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
# Grant identity permissions to read secrets in key vault
# set policy to access secrets in your key vault
az keyvault set-policy -n kv-aks-demo1 --secret-permissions get --spn $identityId
```
Create a SecretProviderClass by using the following YAML, using your own values for `userAssignedIdentityID`, `tenantId`, `keyvault` and the `objects (key/secret/certificate)` to retrieve from your key vault
```yaml
# This is a SecretProviderClass example using user-assigned identity to access key vault
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: kv-aks-demo1-user-msi
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"          # Set to true for using managed identity
    userAssignedIdentityID: <client ID>   # Set the clientID of the user-assigned managed identity to use
    keyvaultName: <key vault name>        # Set to the name of your key vault
    cloudName: ""                         # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: redis-secret        # Object name in this example is redis-secret
          objectType: secret              # object types: secret, key, or cert
          objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
    tenantId: <tenant ID>                 # The tenant ID of the key vault
```
Apply the SecretProviderClass to your cluster
```bash
kubectl apply -f secretproviderclass.yaml
```
Create a pod by using the following YAML
```yaml
# This is a sample pod definition for using SecretProviderClass and the user-assigned identity to access your key vault
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline-user-msi
spec:
  containers:
    - name: busybox
      image: k8s.gcr.io/e2e-test-images/busybox:1.29-1
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store01-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
  volumes:
    - name: secrets-store01-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "kv-aks-demo1-user-msi"
```          
Run the above yaml inline from kubectl from stdin. This will create a pod with volume mounted on it.
```bash
cat <<EOF | kubectl apply -f -
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline-user-msi
spec:
  containers:
    - name: busybox
      image: k8s.gcr.io/e2e-test-images/busybox:1.29-1
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store01-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
  volumes:
    - name: secrets-store01-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "kv-aks-demo1-user-msi"
EOF
```     
### Validate the secrets
After the pod starts, the mounted content at the volume path `/mnt/secrets-store` specified in the deployment YAML is available.
```bash
# show secrets (file) held in secrets-store (directory)
kubectl exec busybox-secrets-store-inline-user-msi -- ls /mnt/secrets-store/

# print a test secret (value) inside 'redis-secret' (file) held in secrets-store (directory)
kubectl exec busybox-secrets-store-inline-user-msi -- cat /mnt/secrets-store/redis-secret

# You can also login to the pod & view the secret stored in file
kubectl exec -it busybox-secrets-store-inline-user-msi /bin/sh 
# cat the file
cat /mnt/secrets-store/redis-secret
```            

## Additional references
* [Manage Kubernetes Secrets with Azure Key Vault](https://nileshgule.medium.com/how-to-manage-kubernetes-secrets-with-azure-key-vault-211cb989b86b)
* [Why mounting secrets as volume is secure in k8s?](https://stackoverflow.com/questions/55620043/is-there-any-security-advantage-to-mounting-secrets-as-a-file-instead-of-passing)

* [Kubernetes Secrets Store CSI Driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver) - allows Kubernetes to mount multiple secrets, keys, and certs stored in enterprise-grade external secrets stores into their pods as a volume. Once the Volume is attached, the data in it is mounted into the container's file system.
* [Azure Key Vault Provider for Secrets Store CSI Driver in an AKS cluster](https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)
    * [Creating Kubernetes Secrets from Azure Key Vault with the CSI Driver](https://samcogan.com/creating-kubernetes-secrets-from-azure-key-vault-with-the-csi-driver/) - The Azure Key Vault CSI Driver is an extension for AKS that allows you to take secrets from Azure Key Vault and mount them as volumes in your pods. Your applications can then read the secret data from a volume mount inside the pod. *<ins>This is great, but again it means you need to change your application to read from that volume.</ins>*
* [Azure Key Vault secrets provider extension for Arc enabled Kubernetes clusters](https://techcommunity.microsoft.com/t5/azure-arc-blog/in-preview-azure-key-vault-secrets-provider-extension-for-arc/ba-p/3002160) 