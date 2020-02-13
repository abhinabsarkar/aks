# Hello AKS cluster
Let's see AKS in action by creating an AKS cluster, hosting an application & accessing it from browser.

```bash
az group create --name rg-aks-demo --location eastus --verbose
az aks create --resource-group rg-aks-demo --name aks-abs-demo --node-count 3 --generate-ssh-keys --verbose
az aks get-credentials --resource-group rg-aks-demo --name aks-abs-demo --verbose
kubectl get nodes --v=9

kubectl apply -f azure-vote.yaml --v=9
kubectl get service azure-vote-front --watch
az group delete --name rg-aks-demo --yes --no-wait --verbose
```