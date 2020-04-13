# exit when any command fails
set -e

# Delete the VM first before deleting any of the other resource as other resources have dependency on it 
# & they cannot be deleted till the VM is deleted
echo "Delete the VM"
az vm delete --name vm-akspc-test --resource-group rg-aks-test --yes --verbose

# Delete all the resources associated with the VM. The associated resources were tagged while creating the vm
echo "Delete the resources associated with the VM"
vmresources=$(az resource list --tag Identifier=VM-Win10 -o table --query "[].id" -o tsv)
for resource in $vmresources
do
 echo "Delete resource $resource"
 az resource delete --ids $resource --verbose
done
