# Azure login to my resource group
# Parameter required - service principal's username, password & tenanat ID
# login using service principal
echo "Login to my private subscription scoped to the resource group rg-aks-test"
az login --service-principal -u $1 -p $2 --tenant $3 --verbose