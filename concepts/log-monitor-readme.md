# AKS Logging & Monitoring

The logs for AKS control plane components are implemented in Azure as [resource logs](https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs) 

You need to create a diagnostic setting to collect resource logs. Create multiple diagnostic settings to send different sets of logs to different locations. See [Create diagnostic settings to send platform logs and metrics to different destinations](https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings) to create diagnostic settings for your AKS cluster.

## AKS Monitoring
Azure Monitor is used to monitor the health and performance of Azure Kubernetes Service (AKS). It includes collection of telemetry critical for monitoring, analysis and visualization of collected data to identify trends. Refer [AKS monitoring](https://docs.microsoft.com/en-us/azure/aks/monitor-aks)

## Container insights
Container insights is a feature in Azure Monitor that monitors the health and performance of managed Kubernetes clusters hosted on AKS in addition to other cluster configurations. Container insights provides interactive views and workbooks that analyze collected data for a variety of monitoring scenarios.  It also collects certain Prometheus metrics, and many native Azure Monitor insights are built-up on top of Prometheus metrics. Refer [Container Insights](https://docs.microsoft.com/en-us/azure/aks/monitor-aks#container-insights)

> Container insights complements and completes E2E monitoring of AKS including log collection which Prometheus as stand-alone tool doesn’t provide. Many customers use Prometheus integration and Azure Monitor together for E2E monitoring.

## Monitoring Control Plane logs
AKS is a managed Kubernetes service such that it doesn't give access to the kube-apiserver, controller-manager, and scheduler pods. Audit Logging in AKS is used to keep a chronological record of calls that have been made to the Kubernetes API server, also known as the control plane. It can be used to investigate suspicious API requests, collect statistics, or create monitoring alerts for unwanted API calls. 

Refer [Resource Logs](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-log-query#resource-logs) stored in [AzureDiagnostics table](https://docs.microsoft.com/en-us/azure/azure-monitor/reference/tables/azurediagnostics).

With respect to the API server options, all the parameters are not documented. These logs can be found in the final args by checking the apiserver log, as kubernetes components typically logs all parameters on start. Those are available following https://docs.microsoft.com/en-us/azure/aks/monitor-aks#collect-resource-logs. See the sample queries below.

![alt txt](/images/apiserver-logs.png)

![alt txt](/images/apiserver-logs-result.png)

> Regarding anonymous-auth=false: This is specifically configured for AKS clusters.  
Regarding kubelet-client-certificate and kubelet-client-key: This is configured if Kubernetes RBAC is enabled. 

## References
* https://docs.microsoft.com/en-us/azure/aks/monitor-aks#collect-resource-logs
* https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs
* https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings
* https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-log-query#resource-logs
* https://docs.microsoft.com/en-us/azure/aks/monitor-aks
* https://medium.com/@weinong/azure-kubernetes-service-control-plane-logs-f8ffa449fd
* https://azure.microsoft.com/en-ca/updates/aks-control-plane-audit-logs/