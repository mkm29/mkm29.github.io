---
title: "Cilium Metrics"
date: 2022-12-02
excerpt: "Update Cilium to expose Prometheus metrics"
tags: [rke2, cilium, devops, cluster, prometheus, servicemonitor]
header:
  overlay_image: /images/businessman_telescope.png
  overlay_filter: 0.5 # same as adding an opacity of 0.5 to a black background
---

# Update Cilium to expose Prometheus metrics

```yaml
Title: Expose Cilium Metrics to Prometheus
Author: Mitch Murphy
Date: 2023-12-15
```

---

- [Update Cilium to expose Prometheus metrics](#update-cilium-to-expose-prometheus-metrics)
- [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Prometheus](#prometheus)
    - [Prometheus Overview](#prometheus-overview)
    - [Prometheus Installation](#prometheus-installation)
  - [Cilium](#cilium)
    - [Cilium and Prometheus](#cilium-and-prometheus)
    - [Cilium Upgrade](#cilium-upgrade)
    - [Cilium ServiceMonitor Verification](#cilium-servicemonitor-verification)
    - [Cilium Grafana Dashboards](#cilium-grafana-dashboards)

# Introduction

This guide serves as a follow up to a previous article covering how to configure RKE2 to use Cilium as the CNI (and fully replace kube-proxy)

## Prerequisites

- RKE2 Cluster
- cilium
- kubectl
- helm

## Prometheus

Prometheus is an open-source monitoring and alerting toolkit designed for reliability and scalability. It is particularly well-suited for monitoring dynamic, cloud-native environments such as Kubernetes. Here's an overview of Prometheus and how it facilitates monitoring in a Kubernetes environment:

### Prometheus Overview

1. **Data Model**:
  - Prometheus follows a multi-dimensional data model, where time-series data is identified by metric names and key-value pairs called labels.
Metrics represent numerical values that can be observed and monitored over time.
2. **Data Retrieval**:
  - Prometheus uses a pull-based approach to collect metrics from monitored targets.
Each target (e.g., a Kubernetes node or container) exposes an HTTP endpoint where Prometheus can fetch metrics.
3. **Scalability**:
  - Prometheus is designed to be highly scalable, making it suitable for large-scale distributed systems like Kubernetes.
It can handle a high volume of metrics from numerous targets.
3. **Query Language**:
  - Prometheus Query Language (PromQL) allows users to express complex queries to analyze and aggregate collected metrics.
PromQL facilitates the creation of custom dashboards and alerts.
Monitoring Kubernetes with Prometheus:
4. **Exporter Components**:
  - Kubernetes exposes a rich set of metrics through its API server, kubelet, and other components.
Prometheus exporters are used to convert these metrics into a format that Prometheus can scrape.
5. **Service Discovery**:
  - Prometheus uses service discovery mechanisms to automatically discover and monitor new instances of services as they are deployed in Kubernetes.
Kubernetes Service Discovery and DNS-based service discovery are commonly used.
6. **Instrumentation**:
  - Kubernetes components are instrumented to expose metrics in a format that Prometheus understands.
Prometheus also supports custom instrumentation, allowing users to expose application-specific metrics.
7. **Alerting and Monitoring**:
  - Prometheus provides a built-in alerting system that allows users to define alerting rules based on metric conditions.
Grafana is often used in conjunction with Prometheus to create dashboards for visualizing metrics.
8. **Integration with Kubernetes Ecosystem**:
  - Prometheus is a CNCF (Cloud Native Computing Foundation) project and is well-integrated with the Kubernetes ecosystem.
It works seamlessly with other tools like Grafana, Alertmanager, and Kubernetes itself.

In summary, Prometheus is a powerful monitoring solution for Kubernetes, offering a flexible and scalable approach to collecting, querying, and alerting based on the metrics generated by the Kubernetes ecosystem. It plays a crucial role in ensuring the reliability and performance of applications deployed in Kubernetes clusters.

### Prometheus Installation

The Prometheus stack includes a few components that greatly help SREs/administrators monitor/observe deployed Kubernetes resources. These include:

* The [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
* Highly available [Prometheus](https://prometheus.io/)
* Highly available [Alertmanager](https://github.com/prometheus/alertmanager)
* [Prometheus node-exporter](https://github.com/prometheus/node_exporter)
* [Prometheus Adapter for Kubernetes Metrics APIs](https://github.com/kubernetes-sigs/prometheus-adapter)
* [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
* [Grafana](https://grafana.com/)

Installing the Prometheus stack on Kubernetes using Helm is a common and convenient approach. Helm is a package manager for Kubernetes that simplifies the deployment and management of applications. Here's a step-by-step guide for Kubernetes administrators on installing the Prometheus stack using Helm:

1. Add Prometheus Helm Repository:

   - Add the Prometheus Helm repository to your Helm client.
  
```yaml
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

2. Create Namespace (Optional):

   * Create a dedicated namespace for Prometheus if desired.

```yaml
kubectl create namespace monitoring
```

3. Install Prometheus Operator:

   * Install the Prometheus Operator using Helm.

```yaml
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

4. Verify Installation:

   * Check the status of the deployed resources.

```yaml
kubectl get pods -n monitoring
```

5. Access Prometheus Dashboard:

   * Prometheus comes with a web-based dashboard. Expose it for access.

```yaml
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090
```

   > Access the Prometheus dashboard at [http://localhost:9090](http://localhost:9090) in your web browser.

6. Access Grafana Dashboard (Optional):

   * Grafana is included in the Prometheus stack. Expose it for access.

```yaml
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

   > Access the Grafana dashboard at [http://localhost:3000](http://localhost:3000) and log in (default credentials are admin/prom-operator).

7. Configure Data Source in Grafana (Optional):

   * Configure Prometheus as a data source in Grafana.
     * URL: http://prometheus-stack-kube-prom-prometheus:9090
     * Save the configuration.

8. Explore and Customize:

   * Explore the Prometheus dashboard and Grafana to monitor your Kubernetes cluster.
   * Customize Grafana dashboards and Prometheus alerting rules as needed.

By following these steps, Kubernetes administrators can easily set up and start using the Prometheus stack for monitoring their Kubernetes clusters. The Helm charts provided by the Prometheus community simplify the installation process and allow for customization based on specific monitoring requirements. Take note of the namespace where you install the prometheus-stack to as we will need to specify that when we upgrade Cilium. Stay tuned when I cover configuring alerts in Prometheus and integration with Alertmanager!

## Cilium

Please refer to my previous post to find more information on what Cilium offers. 

### Cilium and Prometheus

Integrating Cilium and Prometheus in a Kubernetes environment brings several benefits, particularly in terms of exposing advanced metrics and enhancing the observability of your microservices-based architecture. Here are the key advantages of integrating Cilium and Prometheus:

1. **Rich Network Visibility**:
    * **Cilium Network Security**:
      * Cilium provides advanced network security features, including API-aware network security policies, load balancing, and encryption.
      * Prometheus integration with Cilium allows you to capture and visualize metrics related to network security, such as the number of allowed/denied connections and data on network policies.
2. **Fine-Grained Service Metrics**:
    * **Service-Aware Metrics**:
      * Cilium can enforce policies at the service or application layer, providing insights into the interactions between microservices.
      * Prometheus can scrape and expose fine-grained metrics related to service communication, allowing you to monitor service-level performance and troubleshoot issues.
3. **Distributed Tracing**:
    * **Tracepoint Metrics**:
      * Cilium includes tracepoint-based metrics that can be exposed through Prometheus.
      * By integrating Cilium and Prometheus, you can leverage these metrics for distributed tracing, gaining visibility into the flow of requests across microservices and identifying bottlenecks or latency issues.
4. **Security Metrics**:
    * **Security Incident Monitoring**:
      * Cilium enhances security by providing metrics related to security incidents and policy enforcement.
      * Prometheus integration enables monitoring of security-related metrics, helping Kubernetes engineers detect and respond to security events in real-time.
5. **Efficient Resource Utilization**:
    * **Resource Consumption Metrics**:
      * Prometheus can collect and expose metrics related to resource consumption at the network level.
      * This integration allows Kubernetes engineers to optimize resource allocation, identify performance bottlenecks, and ensure efficient use of network resources.
6. **Customizable Dashboards**:
    * **Grafana Integration**:
      * Prometheus integrates seamlessly with Grafana, a popular visualization tool.
      * Engineers can create customizable dashboards in Grafana to visualize Cilium and Kubernetes metrics, providing a comprehensive view of the entire system's health and performance.
7. **Scalability and Performance Monitoring**:
    * **Scalability Metrics**:
      * Cilium and Prometheus integration enables monitoring of metrics related to the scalability and performance of microservices.
      * Engineers can use this information to optimize configurations, scale resources based on demand, and ensure a responsive and scalable application architecture.
8. **Alerting and Automation**:
    * **Alertmanager Integration**:
      * Prometheus integrates with Alertmanager to provide alerting capabilities based on predefined rules.
      * Engineers can set up alerts for key metrics, enabling proactive monitoring and automated responses to potential issues.

In summary, integrating Cilium and Prometheus in a Kubernetes environment enhances observability by providing detailed metrics related to network security, service communication, distributed tracing, and resource utilization. This integration empowers Kubernetes engineers to monitor, analyze, and optimize the performance, security, and scalability of their microservices applications.

### Cilium Upgrade

In order to integrate our previously installed Cilium/Hubble we need to update a few of our Helm values, particularly that involving ServiceMonitors. Update the file containing the values (detailed [here](https://mitchmurphy.io/cilium-rke2/#install-cilium)) to:

```yaml
cluster:
  name: smig-cluster1
  id: 11
prometheus:
  enabled: true
  serviceMonitor:
    enabled: false
dashboards:
  enabled: true
hubble:
  metrics:
    enabled:
    - dns:query;ignoreAAAA
    - drop
    - tcp
    - flow
    - icmp
    - http
    dashboards:
      enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring
      labels:
        release: prometheus-stack
  relay:
    enabled: true
    prometheus:
      enabled: true
      serviceMonitor:
        enabled: true
        namespace: monitoring
        labels:
          release: prometheus-stack
  ui:
    enabled: true
    baseUrl: "/"
version: 1.14.3
operator:
  prometheus:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring
      labels:
        release: prometheus-stack
  dashboards:
    enabled: true
envoy:
  prometheus:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring
      labels:
        release: prometheus-stack
clustermesh:
  apiserver:
    metrics:
      enabled: false
      serviceMonitor:
        enabled: true
        namespace: monitoring
        labels:
          release: prometheus-stack
```

Take note of the label that is added to each ServiceMonitor, this must be present in order for Prometheus to detect the "target" and start scraping it. Now let's upgrade Cilium:

```yaml
cilium upgrade -f cilium.yaml
```

### Cilium ServiceMonitor Verification

n order to verify that Prometheus is picking up these new targets, you need to port-forward and make sure that they show up under Status -> Targets. 

### Cilium Grafana Dashboards

Because we specified in our values file that we wish to create Grafana dashboards, these get created as ConfigMaps and automatically picked up by Grafana. Until we expose Grafana as an Ingress, we must port-forward to it:

```yaml
kubectl port-forward svc/prometheus-stack-grafana 8080:80 &
```

Now visit our [dashboards](http://localhost:8080/dashboards), and click on the Hubble dashboard. Because we have not deployed anything to our cluster we should not see much here, but as you can see Cilium/Hubble provides quite advanced metrics! We will visit this dashboard again after we deploy a few things and test our system!