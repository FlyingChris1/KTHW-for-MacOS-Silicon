# Kubernetes The Hard Way with Multipass

Build a complete Kubernetes cluster from scratch on your local machine using Multipass and Ubuntu VMs.

This project is based on the concepts from Kubernetes The Hard Way. It gives you the option to set up your cluster manually or automate the repetitive steps while preserving the educational value of manually bootstrapping Kubernetes components.

> Note - This repo only work for MacOS devices with an M1/2/3/4/5 chip due to the ARM64 architecure

The result is a fully functional Kubernetes cluster consisting of:

- 1 Control Plane Node (`controller-1`)
- 2 Worker Nodes (`worker-1`, `worker-2`)
- etcd
- kube-apiserver
- kube-controller-manager
- kube-scheduler
- kubelet
- kube-proxy
- Calico CNI

Tested with:

- macOS
- Multipass
- Ubuntu 26.04 LTS
- Kubernetes v1.34.1

---

# Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Cluster Verification](#cluster-verification)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)

---

# Architecture

![Cluster Architecture](Cluster-Architecture.png)

Cluster layout:

| Node | IP Address | Role |
|--------|------------|--------|
| controller-1 | 172.22.5.11 | Control Plane |
| worker-1 | 172.22.5.21 | Worker |
| worker-2 | 172.22.5.22 | Worker |

---

# Prerequisites

Install the following tools on your workstation.

## Multipass

```bash
brew install multipass
```

Verify:

```bash
multipass version
```

---

## PowerShell

Required to execute the Multipass provisioning script.

```bash
brew install --cask powershell
```

Verify:

```bash
pwsh --version
```

---

## Git

```bash
git --version
```

---

# Quick Start

## Set up the cluster manually

[Follow these steps](docs/01-prerequisites-and-vms.md)

## Set up the cluster automated

### 1. Clone the repository

```bash
git clone https://github.com/FlyingChris1/KTHW-for-MacOS-Silicon.git
cd KTHW-for-MacOS-Silicon
```

---

### 2. Create the virtual machines

```bash
cd multipass
pwsh ./run.ps1
cd ..
```

This creates:

```text
controller-1
worker-1
worker-2
```

and configures:

- networking
- hostname resolution
- SSH access from controller-1 to workers

---

### 3. Copy the repository to controller-1

```bash
multipass exec controller-1 -- mkdir -p /home/ubuntu/kubernetes-the-hard-way

multipass transfer -r . controller-1:/home/ubuntu/kubernetes-the-hard-way
```

---

### 4. Connect to controller-1

```bash
multipass shell controller-1
```

---

### 5. Run the automated installer

```bash
cd ~/kubernetes-the-hard-way

chmod +x scripts/*.sh

bash scripts/install-all.sh
```

The installer automatically performs:

```text
01 Certificates
02 Kubeconfigs
03 Encryption Configuration
04 etcd
05 Control Plane
06 Workers
07 Calico
99 Verification
```

Installation typically takes several minutes.

---

# Usage

## Verify cluster health

```bash
kubectl get nodes \
  --kubeconfig ~/admin.kubeconfig
```

Expected:

```text
NAME           STATUS   ROLES    AGE   VERSION
controller-1   Ready    <none>   ...
worker-1       Ready    <none>   ...
worker-2       Ready    <none>   ...
```

---

## View system pods

```bash
kubectl get pods -A \
  --kubeconfig ~/admin.kubeconfig
```

---

## Cluster information

```bash
kubectl cluster-info \
  --kubeconfig ~/admin.kubeconfig
```

---

## Test workload

```bash
kubectl create deployment nginx \
  --image=nginx \
  --kubeconfig ~/admin.kubeconfig

kubectl get pods \
  --kubeconfig ~/admin.kubeconfig
```

---

# Cluster Verification

Verify nodes:

```bash
kubectl get nodes \
  --kubeconfig ~/admin.kubeconfig
```

Verify networking:

```bash
kubectl get pods -n kube-system \
  --kubeconfig ~/admin.kubeconfig
```

Expected:

```text
calico-node
calico-kube-controllers
```

should be running.

---

# Cleanup

Destroy the entire environment:

```bash
multipass stop --all

multipass delete --all

multipass purge
```

---

# Troubleshooting

## View node status

```bash
kubectl get nodes \
  --kubeconfig ~/admin.kubeconfig
```

---

## Check kubelet

```bash
sudo systemctl status kubelet
```

---

## Check API server

```bash
sudo systemctl status kube-apiserver
```

---

## Check etcd

```bash
sudo systemctl status etcd
```

---

## View logs

```bash
journalctl -u kubelet -f
```

```bash
journalctl -u kube-apiserver -f
```

```bash
journalctl -u etcd -f
```

---
