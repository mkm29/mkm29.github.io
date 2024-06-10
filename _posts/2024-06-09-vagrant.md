---
title: "Cilium and Istio Harmony"
date: 2024-03-16
excerpt: "Update Cilium to work with Istio and create a self-signed certificate for Istio."
tags: [rke2, cilium, devops, cluster, istio, tls]
header:
  overlay_image: /images/businessman_telescope.png
  overlay_filter: 0.5 # same as adding an opacity of 0.5 to a black background
---

# Update Cilium to work with Istio and create a self-signed certificate for Istio

```yaml
Title: Update Cilium to work with Istio and create a self-signed certificate for Istio
Author: Mitch Murphy
Date: 2024-03-16
```

- [Update Cilium to work with Istio and create a self-signed certificate for Istio](#update-cilium-to-work-with-istio-and-create-a-self-signed-certificate-for-istio)
  - [Introduction](#introduction)
  - [Pre-requisites](#pre-requisites)
  - [Update Cilium chart](#update-cilium-chart)
  - [Create Istio Namespace](#create-istio-namespace)
  - [Create self-signed certificate](#create-self-signed-certificate)


## Introduction

In this post we are going to update Cilium to work with Istio and create self-signed certificates for Istio.

As discussed in my previous [post](https://mitchmurphy.io/cilium-rke2/), Cilium, when replaceing [kube-proxy](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/), provides very powerful features which can increase performance for large Kubernetes clusters. While Cilium does offer a service mesh (with mTLS), it is still in beta and other solutions such as Istio are quite mature and offer a lot of capabilities.

When utilizing alternative networking infrastructure, the underlying Cilium eBPF implementation that replaces kube-proxy may inadvertently reveal itself and lead to unexpected behaviors. This becomes evident when attempting to integrate Istio service mesh with Cilium's kube-proxy replacement, as the default replacement of kube-proxy can disrupt Istio's functionality.

## Pre-requisites

- [RKE2](https://rke2.io/)
- [Cilium](https://cilium.io/)
- [Istio](https://istio.io/)
- [Helm](https://helm.sh/)
- [Make](https://www.gnu.org/software/make/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

This blog [post](https://www.solo.io/blog/istio-cilium-kube-proxy-replacement/) had a profound impact on the creation of the one you're reading now.

## Update Cilium chart

```bash
helm upgrade cilium \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set socketLB.hostNamespaceOnly=true
```

## Create Istio Namespace

```bash
kubectl create namespace istio-system
```

_Note_ that you can also specify the creation of the namespace in the below script.

## Create self-signed certificate

For this step we are going to use a few scripts from the istio repository. These tools can be found [here](../tools/). The first step is to create the namespace and then generate the self-signed certificate that Istio will be using (here we are assuming 3 clusters). The following script will create the certificates and then create the secrets in each cluster (you must have the `kubeconfig` for each cluster in order to run the script).

You can find the scripts at the following location: [istio-tools](../scripts/istio), the specific script is [make-certs.sh](../scripts/istio/make-certs.sh).

_TODO_: real world example(s)
