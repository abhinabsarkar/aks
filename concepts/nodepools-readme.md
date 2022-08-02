# AKS Node Pools

[Node Pools explained - youtube](https://www.youtube.com/watch?v=45UxnRj11_g)
* What is a node pool
* Why node pools are needed
* Demo on how to create a nodepool

[Taints, Tolerations, NodeSelector in AKS](https://www.youtube.com/watch?v=aGT3UtZoiA0&list=PLp_fsLj4v7gSDKJbODbdvjOtDx3-35ae6&index=3)
* How pods are scheduled in a node pool
* Demo using Taints, Tolerations
* Demo using Node Selector 
* Talks about Node affinity & Pod affinity
    * [Kubernetes scheduler explained with a story](https://www.azuremonk.com/blog/kube-scheduler)

## Summary
* Node pools should not be used for application isolation. The purpose (and supporting features) of node pools are to offer different node configurations to the cluster in a scalable fashion (using VMSS in the case of AKS).
* AKS (and most managed K8S implementations) treat all nodes in all node pools are one large set of nodes by default. Using node pools without additional controls provides no isolation.
* Application isolation should be enforced through namespaces (and associated permissions), network policies, and other relevant cluster security configuration.
* In some cases, there can be correlation between application isolation and node pools, in the case where specific applications require specific node configurations [(FIPS enabled node pool)](https://docs.microsoft.com/en-us/azure/compliance/offerings/offering-fips-140-2) which is not desired for all applications (usually due to performance impacts). However, the use of node pools is not for the isolation, but rather to offered hardened nodes in the cluster.
* Using node pools for application isolation leads to inefficient clusters, where nodes are underutilized. Applications that require that same node configuration should be deployed in the same node pool to maximize node use and reduce the overall cluster costs.
* It's recommended to schedule your application pods on user node pools, and dedicate system node pools to only critical system pods. This prevents rogue application pods from accidentally killing system pods. Enforce this behavior with the `CriticalAddonsOnly=true:NoSchedule` [taint](https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools#setting-nodepool-taints) for your system node pools. Refer [Microsoft documentation](https://docs.microsoft.com/en-us/azure/aks/use-system-pools?tabs=azure-cli#add-a-dedicated-system-node-pool-to-an-existing-aks-cluster).


![alt txt](/images/aks-nodepools.jpg)