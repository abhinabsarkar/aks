# Kubernetes Architecture

## Overview & high level architecture
[Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) is a portable, extensible, open-source platform for managing containerized workloads and services.

It has a distributed architecture consisting of at least one master ([for HA, it requires atleast three machines](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)) and multiple compute nodes. The master is responsible for exposing the application program interface (API), scheduling the deployments and managing the overall cluster. Each [node](https://kubernetes.io/docs/concepts/architecture/nodes/) runs a container runtime, such as Docker, along with an agent ([kubelet](https://kubernetes.io/docs/concepts/overview/components/#kubelet)) that communicates with the master. The node also runs additional components for logging, monitoring, service discovery and optional add-ons. They expose compute, networking and storage resources to applications. Nodes can be virtual machines (VMs) running in a cloud or bare metal servers running within the data center.

![Alt text](/images/k8s-architecture-101.jpg)

Before getting into more details, let's understand how Kubernetes works from an abstract point of view. Kubernetes serves as a **constant reconciliation loop**. Desired state is submitted to the API server, then controllers and Kubelets and other components within the system constantly work toward achieving this desired state.

![Alt text](/images/k8s-loop.jpg)

## Let's get a bit closer - Components of Master - Control Plane

[Master](https://kubernetes.io/docs/concepts/overview/components/#master-components)
* API server – Whenever a request/command is sent via client (Kubectl), it goes through series of steps i.e Authentication, Authorization and Admission control.
* ETCD – It is reliable clustered key value store (DB). etcd stores the persistent master state while other components watch etcd for changes to bring themselves into the desired state.
* Replication Controller – It ensures that a specified number of replicas of a pod are running at all times. If you deploy a pod and set replica count to three, the replication controller ensures that three replicas will be running at any given point in time. If one of the replicas die, the replication controller will schedule a new replica on a different node or the same node.
* Scheduler - responsible for determining placement of new pods onto nodes within the cluster. It reads data from the pod and finds a node that is a good fit based on configured policies. It does not modify the pod and just creates a binding for the pod that ties the pod to the particular node.

    ![Alt text](/images/k8s-master.jpg)

## Let's get a bit closer - Components of Node - Worker
[Node](https://kubernetes.io/docs/concepts/overview/components/#node-components)
* Pod - smallest compute unit that can be defined, deployed, and managed having one or more containers deployed together on one host. Each pod is allocated its own internal IP address, and containers within pods can share their local storage and networking. Pods are immutable when running. Pod is like a container hosting other containers. In Kubernetes world, Pods are scaled, not the individual containers.

    ![Alt text](/images/k8s-pod-design.jpg)

    The Pods don’t serve traffic till they are exposed as a Kubernetes Service – which acts as a load balancer for the replicated pods.
    ![Alt text](/images/k8s-service.jpg)

* Kubelet - primary “node agent” that runs on each node. They ensure the containers described in the PodSpecs (YAML file describing the Pod) are running and healthy.
* Kube Proxy - runs on each node. It acts as a network proxy connecting locally running pods to outside world. It also functions as a load balancer (i.e. Services which provides a VIP and acts as load balancer) for groups of pods sharing the same label (i.e. if a node has multiple pods balances the traffic between those pods).
> [Kubernetes Networking explained](https://www.youtube.com/watch?v=B_7nHbtWKrs)
* Container Runtime - software that is responsible for running containers. Kubernetes supports several container runtimes: [Docker](https://www.docker.com/), [containerd](https://containerd.io/), etc.

    ![Alt text](/images/k8s-node.jpg)

## Kubernetes Architecute - The complete picture
The definition of Kubernetes objects, such as pods, replica sets and services, are submitted to the master. Based on the defined requirements and availability of resources, the master schedules the pod on a specific node. The node pulls the images from the container image registry and coordinates with the local container runtime to launch the container. etcd which acts as the single source of truth for all components of the Kubernetes cluster. The master queries etcd to retrieve various parameters of the state of the nodes, pods and containers. This architecture of Kubernetes makes it modular and scalable by creating an abstraction between the applications and the underlying infrastructure.

![Alt text](/images/k8s-architecture.jpg)

## Route traffic to the cluster
Ingress Controller - An [ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) is a Kubernetes resource that routes traffic from outside your cluster to services within the cluster. You must have an ingress controller like [F5](https://clouddocs.f5.com/products/connectors/k8s-bigip-ctlr/v1.11/) or [HAProxy](https://github.com/haproxytech/kubernetes-ingress) to satisfy an Ingress. Only creating an Ingress resource has no effect.
