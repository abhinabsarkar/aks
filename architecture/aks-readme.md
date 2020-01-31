# AKS architecture

AKS cluster is divided into two components:
* Cluster master nodes providing the core Kubernetes services and orchestration of application workloads.
* Nodes that run application workloads.

![Alt text](/images/cluster-master-and-nodes.jpg)

### Cluster master
When an AKS cluster is created, a cluster master is automatically created and configured. This cluster master is provided as a managed Azure resource abstracted from the user. There's no cost for the cluster master, only the nodes that are part of the AKS cluster.

The cluster master includes the following core Kubernetes components:
* kube-apiserver - It exposes the Kubernetes APIs which can be accessed via kubectl cli or the Kubernetes dashboard.
* etcd - It is a key value DB store where the state of Kubernetes cluster and configuration are stored.
* kube-scheduler - It determines the nodes that can run the application workload and starts them. 
* kube-controller-manager - It ensures that a specified number of replicas of a pod are running at all times. If you deploy a pod and set replica count to three, it ensures that three replicas will be running at any given point in time. If one of the replicas die, it will schedule a new replica on a different node or the same node.

AKS provides a single-tenant cluster master, with a dedicated API server, Scheduler, etc. When the user defines the number and size of the nodes, the Azure platform configures the secure communication between the cluster master and nodes.
Upgrades to Kubernetes are orchestrated through the Azure CLI or Azure portal, which upgrades the cluster master and then the nodes. To troubleshoot possible issues, the cluster master logs through Azure Monitor logs can be used as there no direct access to the cluster master.

### Nodes
AKS cluster has one or more nodes, which is an Azure virtual machine (VM) that runs the Kubernetes node components and container runtime:
* kubelet - It is the primary “node agent” that runs on each node. They ensure the containers described in the PodSpecs (YAML file describing the Pod) are running and healthy.
* kube-proxy - Virtual networking is handled by the kube-proxy on each node. The proxy routes network traffic and manages IP addressing for services and pods.
* container runtime - It allows containerized applications to run and interact with additional resources such as the virtual network and storage. In AKS, Moby is used as the container runtime.

![Alt text](/images/aks-node-resource-interactions.jpg)