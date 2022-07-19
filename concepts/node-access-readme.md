# Connect to Azure Kubernetes Service (AKS) cluster nodes

## Create an interactive shell connection to a Linux node
```bash
# List the AKS nodes
kubectl get nodes -o wide
# Start a privileged container on a node & connect to it 
kubectl debug node/<node-name> -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
```
> You can interact with the node session by running `chroot /host` from the privileged container

```bash
# Check kubelet run status
systemctl status kubelet
# Check kubelet start command
systemctl status kubelet | grep /usr/local/bin/kubelet
```

Refer the link below for more details on how to connect to the windows node.

## References
* https://docs.microsoft.com/en-us/azure/aks/node-access