# Azure logout from my resource group
# Parameter required - service principal username
# logout the service principal
echo "Logout from my private subscription scoped to the resource group rg-aks-test"
az logout --username $1
