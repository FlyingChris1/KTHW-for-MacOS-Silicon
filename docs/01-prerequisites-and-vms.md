# 01 - Prerequisites and VM Preparation

This guide explains how to manually build the Kubernetes cluster after the Multipass VMs have been created.

The VM creation itself is handled by:

```bash
cd multipass
pwsh ./run.ps1
```

The `run.ps1` script prepares the base environment:

- Creates the VMs:
  - `controller-1`
  - `worker-1`
  - `worker-2`
- Applies static network configuration
- Adds `/etc/hosts` entries
- Prepares SSH access from `controller-1` to both workers

This SSH preparation is important because the manual setup uses `controller-1` to copy certificates and configuration files to `worker-1` and `worker-2`.

## Cluster Layout

| Node | IP Address | Purpose |
|---|---:|---|
| controller-1 | 172.22.5.11 | Control Plane and Kubernetes Node |
| worker-1 | 172.22.5.21 | Worker Node |
| worker-2 | 172.22.5.22 | Worker Node |

## Verify VMs

On your host machine:

```bash
multipass list
```

Expected:

```text
controller-1   Running
worker-1       Running
worker-2       Running
```

## Login to controller-1

```bash
multipass shell controller-1
```

## Verify name resolution and SSH

Run this on `controller-1`:

```bash
ping -c 1 worker-1
ping -c 1 worker-2

ssh worker-1 hostname
ssh worker-2 hostname
```

Expected:

```text
worker-1
worker-2
```

## Install kubectl on controller-1

```bash
cd /tmp

curl -LO https://dl.k8s.io/release/v1.34.1/bin/linux/arm64/kubectl

chmod +x kubectl

sudo mv kubectl /usr/local/bin/kubectl

kubectl version --client
```

Expected:

```text
Client Version: v1.34.1
```

### [Next step](02-certificate-authority-and-certificates.md)
