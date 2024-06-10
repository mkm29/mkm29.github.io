---
title: "Vagrant + RKE2 + Cilium"
date: 2024-06-09
excerpt: "Use Vagrant to provision and install RKE2 and Cilium"
tags: [rke2, cilium, devops, cluster, vagrant]
header:
  overlay_image: /images/vagrant-kubernetes.png
  overlay_filter: 0.5 # same as adding an opacity of 0.5 to a black background
---

# Use Vagrant to provision and install RKE2 and Cilium

```yaml
Title: Use Vagrant to provision and install RKE2 and Cilium
Author: Mitch Murphy
Date: 2024-06-09
```
- [Use Vagrant to provision and install RKE2 and Cilium](#use-vagrant-to-provision-and-install-rke2-and-cilium)
  - [Introduction](#introduction)
    - [Pros](#pros)
    - [Cons](#cons)
  - [Provision RKE2](#provision-rke2)
    - [Benefits of Using Vagrant for Local Kubernetes Cluster:](#benefits-of-using-vagrant-for-local-kubernetes-cluster)
    - [Challenges:](#challenges)
  - [Installation](#installation)
    - [Install Virtualization Provider](#install-virtualization-provider)
    - [Install Vagrant](#install-vagrant)
    - [Install Required Plugins (Optional)](#install-required-plugins-optional)
    - [Ensure Kernel Modules for Virtualization are Loaded](#ensure-kernel-modules-for-virtualization-are-loaded)
    - [Verify Installation](#verify-installation)
  - [Configuration](#configuration)


## Introduction

Vagrant is an open-source tool designed to create and manage virtualized development environments. It allows developers to define and configure lightweight, reproducible, and portable virtual environments using a simple configuration file called a Vagrantfile. Vagrant integrates with various virtualization technologies like VirtualBox, VMware, and Docker, enabling users to set up and tear down development environments quickly and consistently. By using Vagrant, developers can ensure that their development environments are identical across different machines, reducing the "works on my machine" problem and facilitating collaboration among team members.

### Pros

- Consistency and Reproducibility: Vagrant ensures that development environments are consistent across all team members' machines, reducing discrepancies between development, testing, and production environments.
- Easy Setup and Configuration: With Vagrant, setting up a development environment is straightforward and automated, often requiring just a single command to get started.
- Isolation: Vagrant environments are isolated from the host system, minimizing the risk of conflicts with other applications and dependencies.
- Flexibility: Vagrant supports multiple virtualization providers and can be used with various provisioning tools like Ansible, Puppet, and Chef, providing flexibility in how environments are configured and managed.

### Cons

- Resource Intensive: Running multiple Vagrant environments can be resource-intensive, requiring significant CPU, memory, and disk space, especially on less powerful machines.
- Learning Curve: For new users, there can be a learning curve associated with understanding Vagrant and its configuration files, particularly when integrating with complex provisioning tools.
- Performance Overheads: Virtualized environments may introduce performance overheads compared to running applications natively on the host machine, which can impact development and testing speeds.
- Dependency on Virtualization Providers: Vagrant relies on external virtualization providers, and any issues or limitations with these providers can affect the performance and reliability of Vagrant environments.

## Provision RKE2

Vagrant can be utilized to configure and provision a local Kubernetes cluster by automating the setup of virtual machines (VMs) that act as the nodes of the cluster. Here’s a step-by-step outline of how this can be achieved:

1. Define Vagrantfile:
  - Create a Vagrantfile to define the configuration for the VMs. This file specifies the number of VMs, their resources (CPU, memory, etc.), and the base image to use.
  - Example configuration might include one VM as the master node and two or more VMs as worker nodes.
2. Provisioning the VMs:
  - Use provisioning scripts or configuration management tools (like Ansible, Puppet, or Chef) within the Vagrantfile to install necessary dependencies on the VMs. This typically includes Docker, kubeadm, kubectl, and kubelet.
  - The provisioning script also sets up networking between the VMs to ensure they can communicate with each other.
3. Initialize the Kubernetes Master Node:
  - After the VMs are up and running, SSH into the master node and run kubeadm init to initialize the Kubernetes master. This command sets up the control plane and generates a command (with a token) to join the worker nodes to the cluster.
4. Configure kubectl:
  - Configure the kubectl command-line tool on the master node to interact with the cluster by copying the kubeconfig file to the appropriate location.
5. Join Worker Nodes:
  - SSH into each worker node and run the join command provided by kubeadm init. This command joins the worker nodes to the Kubernetes cluster, making them part of the cluster's node pool.
6. Network Setup:
  - Deploy a network plugin (such as Flannel, Calico, or Weave) to handle pod networking. This can be done by applying the relevant YAML file using kubectl apply -f <network-plugin.yaml>.
7. Verify the Cluster:
  -Once all nodes are joined and the network plugin is configured, verify the cluster status by running kubectl get nodes on the master node. All nodes should be in a "Ready" state.

### Benefits of Using Vagrant for Local Kubernetes Cluster:

- Reproducibility: Easily recreate the cluster environment for consistent development and testing.
- Isolation: The cluster runs in isolated VMs, preventing interference with the host system.
- Automation: Automated setup reduces manual configuration time and potential errors.

### Challenges:

- Resource Consumption: Multiple VMs can be resource-intensive.
- Configuration Complexity: Initial setup and configuration can be complex, especially for users unfamiliar with Vagrant or Kubernetes.

## Installation

For the purposes of this tutorial, we will be using a Debian based system (Pop!_OS). To run Vagrant on a Debian-based system, you need to ensure that several prerequisites are met. Here is a comprehensive list of the prerequisites and steps to get Vagrant up and running:

### Install Virtualization Provider  

Vagrant requires a virtualization provider to create and manage virtual machines. The most commonly used provider is VirtualBox, but you can also use others like VMware or Docker. Here, we will focus on VirtualBox.

```bash
sudo apt update
sudo apt install -y virtualbox
```

### Install Vagrant

Next, you need to install Vagrant. You can download the .deb package from the official Vagrant website or use the package manager.

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update
sudo apt install -y vagrant
```

There are a few other packages that you will need:

```bash
sudo apt update && sudo apt install -y libvirt-dev qemu-kvm libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager libvirt-doc ruby-libvirt qemu libvirt-clients ebtables dnsmasq-base libxslt-dev libxml2-dev zlib1g-dev ruby-dev libguestfs-tools
```

### Install Required Plugins (Optional)

Depending on your use case, you might need to install additional Vagrant plugins. For example, if you're using a different provider or need specific functionalities.

```bash
PLUGINS=vagrant-vboxmanage vagrant-vbguest vagrant-libvirt vagrant-reload
for PLUGIN in $PLUGINS; do
  vagrant plugin install $PLUGIN
done
```

### Ensure Kernel Modules for Virtualization are Loaded

For VirtualBox to work correctly, ensure that the necessary kernel modules are loaded.

```bash
sudo modprobe vboxdrv
sudo modprobe vboxnetflt
sudo modprobe vboxnetadp
```

### Verify Installation

To confirm that Vagrant and VirtualBox are installed correctly, you can check their versions.

```bash
vagrant --version
vboxmanage --version
```

## Configuration

I have prepared a simple `Vagrantfile` for you to get started with standing up an RKE2 v1.30.1 cluster, Cilium, K9s and Helm. Stay tuned for more details regarding this configuration (this will more than likely be reflected in the README of the repository). [Link](https://github.com/gaianetes/kubula/blob/feature/packer-rocky/infrastructure/vagrant/Vagrantfile) to repository.