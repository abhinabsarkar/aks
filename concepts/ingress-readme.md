# Ingress

Ingress is a kubernetes object that exposes HTTP and HTTPS routes from outside the cluster to [Services](/concepts/service-readme.md) within the cluster like a reverse proxy. Traffic routing is controlled by rules defined on the Ingress resource. An Ingress can be configured to give Services externally-reachable URLs, load balance traffic, terminate SSL / TLS, and offer name based virtual hosting.

Only creating an Ingress resource in kubernetes has no effect. An **Ingress Controller** is required to satisfy an Ingress.

An **Ingress controller** is responsible for fulfilling the Ingress, usually with a load balancer, though it may also configure your edge router or additional frontends to help handle the traffic. In case of **AKS**, you can use
* [Azure Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/overview), using the [Application Gateway Ingress Controller](https://azure.github.io/application-gateway-kubernetes-ingress/)
* [NGINX Ingress Controller](https://docs.microsoft.com/en-us/azure/aks/ingress-tls)

> For additional ingress controllers, refer this [link](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/#additional-controllers)

In case of AKS, when a LoadBalancer type Service is created, an underlying Azure load balancer resource is created. The load balancer is configured to distribute traffic to the pods in your Service on a given port. The LoadBalancer only works at layer 4 - the Service is unaware of the actual applications, and can't make any additional routing considerations.

Ingress controllers work at layer 7, and can use more intelligent rules to distribute application traffic. A common use of an Ingress controller is to route HTTP traffic to different applications based on the inbound URL.

![Alt Text](/images/aks-ingress.jpg)

An Ingress does not expose arbitrary ports or protocols. Exposing services other than HTTP and HTTPS to the internet typically uses a service of type **Service.Type=NodePort** or **Service.Type=LoadBalancer**.

A sample Ingress kubernetes object which uses the http-application-routing (specific to AKS *see annotation* )
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: hellopython
  annotations:
    kubernetes.io/ingress.class: addon-http-application-routing
spec:
  rules:
  - host: <host_name>
    http:
      paths:
      - backend:
          serviceName: hellopython
          servicePort: 80
        path: /
```

Each HTTP rule in Ingress contains the following information:
* An optional host. If no host is specified, the rule applies to all inbound HTTP traffic through the IP address specified, else the rules apply to that host.
* A list of paths, each of which has an associated backend defined with a serviceName and servicePort. Both the host and path must match the content of an incoming request before the load balancer directs traffic to the referenced Service.
* A backend, which is a combination of Service and port names. HTTP (and HTTPS) requests to the Ingress that matches the host and path of the rule are sent to the listed backend.
> A default backend is often configured in an Ingress controller to service any requests that do not match a path in the spec.

**TLS** - Ingress can be secured by specifying a Secret that contains a TLS private key and certificate. Currently the Ingress only supports a single TLS port, 443, and assumes TLS termination.

**Loadbalancing** - An Ingress controller is bootstrapped with some load balancing policy settings that it applies to all Ingress, such as the load balancing algorithm, backend weight scheme, and others. More advanced load balancing concepts (e.g. persistent sessions, dynamic weights) are exposed through the load balancer used for a Service.

**Failing across availability zones** - Always deploy at least two replicas of Ingress Controller for high availability. The documentation for the respective cloud providers can be found [here](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/#additional-controllers).

