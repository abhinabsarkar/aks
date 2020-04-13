# Create a VM in azure and assciate it with an existing network

# Get a windows 10 image
echo "Get the windows 10 image urn"
windows10=$(az vm image list --publisher MicrosoftWindowsDesktop --offer Windows-10 --sku 19h2-pro --all --query "[0].urn" -o tsv)
echo $windows10

# Parameter required - admin-username & password
echo "Create VM and attach it to the existing Virtual Network"
az vm create --name vm-akspc-test --resource-group rg-aks-test \
	--admin-username $1 --admin-password $2 \
	--image $windows10 \
	--size Standard_D4_v3 \
	--location eastus2 \
	--vnet-name vn-aks-test \
	--subnet sn-aks-test \
	--tags Identifier=VM-Win10 \
	--verbose
