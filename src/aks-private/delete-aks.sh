# Delete AKS cluster. Not using the --no-wait switch as have to clean other resources as well
echo "Delete AKS cluster"
az aks delete --name aks-test --resource-group rg-aks-test --yes --verbose