# exit when any command fails
set -e

# Create VNet
echo "Create Virtual Network"
az network vnet create \
   -g rg-aks-test -n vn-aks-test \
   --address-prefix 10.0.0.0/16 \
   --subnet-name sn-aks-test \
   --subnet-prefix 10.0.0.0/24 \
   --tags Identifier=VNET-AKS \
   --verbose

# Get the subnet-id
echo "Get the subnet id"
# az network vnet subnet list --resource-group rg-aks-test --vnet-name vn-aks-test --query "[0].id"
subnetid=$(az network vnet subnet list \
    --resource-group rg-aks-test \
    --vnet-name vn-aks-test \
    --query "[0].id" \
    --output tsv) # json output wraps the id in quotations. Include --output tsv, you should be able to pass that id value to the next command.
echo "Subnet id -  $subnetid"

# Create AKS private cluster & associate it with the subnet
# Parameter required - subscription id
echo "Create AKS private cluster & associate it with the subnet"
az aks create \
    --resource-group rg-aks-test \
    --name aks-test \
    --load-balancer-sku standard \
    --network-plugin azure \
    --vnet-subnet-id $subnetid \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24 \
    --enable-private-cluster \
    --node-count 1 \
    --node-vm-size Standard_DS3_v2 \
    --service-principal $1 \
    --client-secret $2 \
    --subscription $3 \
    --tags Identifier=AKS-Private \
    --generate-ssh-keys \
    --verbose
