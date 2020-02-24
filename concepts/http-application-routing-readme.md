# HTTP application routing

The HTTP application routing is an add-on which is designed to quickly create an ingress controller and access applications in AKS cluster. This add-on is **not recommended for production use**.

The add-on deploys two components: 
* **[Ingress controller](/concepts/ingress-readme.md)** - The Ingress controller is exposed to the internet by using a Kubernetes service of type LoadBalancer. The Ingress controller watches and implements Kubernetes Ingress resources, which creates routes to application endpoints.
* **External-DNS controller** - It watches for Kubernetes Ingress resources and creates DNS A records in the cluster-specific DNS zone.

The HTTP application routing solution can only be triggered on Ingress resources that are annotated as shown below:
```yaml
annotations:
  kubernetes.io/ingress.class: addon-http-application-routing
```
Sample ingress kubernetes object for http application routing shown below:
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: hellopython
  annotations:
    kubernetes.io/ingress.class: addon-http-application-routing
spec:
  rules:
  - host: <hostname>
    http:
      paths:
      - backend:
          serviceName: hellopython
          servicePort: 80
        path: /
```
To see it in action, create an AKS cluster with http application add-on enabled
```bash
# Create AKS cluster with http application routing
az aks create --resource-group rg-aks-demo --name aks-abs-demo --node-count 1 --generate-ssh-keys --enable-addons http_application_routing --verbose
```
This deploys the Azure DNS zone as well. Retrieve the DNS zone name to deploy applications to the AKS cluster.
```bash
# Retrieve the DNS zone name
az aks show --resource-group rg-aks-demo --name aks-abs-demo --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName -o table
```
To see an application on action, get the hostname & replace the current host value 'hellopython.<hostname>' in the file [abs-demo-http-application-routing.yaml](/src/abs-demo-http-application-routing.yaml) with the hostname retrieved using the previous command.

Deploy the file and apply the kubernetes objects as shown below
```bash
# Get aks credentials and write it in kubeconfig
az aks get-credentials --resource-group rg-aks-demo --name aks-abs-demo --overwrite-existing --verbose
# Apply kubernetes resources
kubectl apply -f abs-demo-http-application-routing.yaml
```

To check the events after applying the kubernetes objects
```bash
kubectl get events
```
