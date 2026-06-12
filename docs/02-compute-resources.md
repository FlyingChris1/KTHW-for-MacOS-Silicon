# Provisioning Compute Resources

## Multipass Cloud Init

Multipass takes advantage of [cloud-init](https://ubuntu.com/blog/using-cloud-init-with-multipass) yaml files to customize hosts on launch. In the `multipass` directory there are two cloud-init files that are used to create all of the hosts.

1. `controller-cloud-config.yaml`
    - used for controller-1, controller-2, and loadbalancer

2. `worker-cloud-config.yaml`
    - used for worker-1 and worker-2
    - installs docker 20.10.12 as outlined in the [Offical Docker installation documention](https://docs.docker.com/engine/install/ubuntu/)

## Netplan

By default multipass will dynamically allocate an IP Address for each host. However, for kubernetes setup we need to maintain static IPs across the hosts. In order to set static IPs we will be using [Netplan](https://netplan.io/) yaml configuration files. In the `multipass` directory there are netplan configuration files for each host which will be copied to `/etc/netplan/` on each respective host.

e.g `01-controller-1-network.yaml` looks like the following:

```
network:
  version: 2
  renderer: networkd
  ethernets:
      dhcp4: yes
      addresses: 
        - 172.22.5.11/20
```
## Starting the VMs

There is a `run.ps1` in the `multipass` directory that will run all of the multipass commands to setup our VM hosts. (If running on another OS, please rename `run.ps1` with the correct extension as it only contains multipass commands)

This does the below:

- Deploys 5 VMs - 2 Controllers, 2 Workers and 1 Loadbalancer
- All are running the latest Ubuntu LTS (20.04 LTS at the moment)
- Install's Docker on Worker nodes
- Runs the below command on all nodes to allow for network forwarding in IP Tables. This is required for kubernetes networking to function correctly.
  > `sysctl net.bridge.bridge-nf-call-iptables=1`
- Copies the netplan yaml to each host and set's IP addresses in the range 172.55.5.*
- Restarts all of the hosts 

```
cd multipass

.\run.ps1
```

## Hosts

| VM Name      | Purpose       | IP          |
|--------------|---------------|-------------|
| controller-1 | Control Plane | 172.55.5.11 |
| controller-2 | Control Plane | 172.55.5.12 |
| worker-1     | Worker        | 172.55.5.21 |
| worker-2     | Worker        | 172.55.5.22 |
| loadbalancer | LoadBalancer  | 172.55.5.30 |

List all hosts in multipass (note: each hosts will have two IP addresses, one that was origianlly dynamically allocated and one static address that we added via netplan). Our IP address may not show in the list command below. 
```
multipass list
```

## Connect to the Hosts

```
multipass shell controller-1
```

## Verify Environment

- Ensure all VMs are up
- Ensure VMs are assigned the above IP addresses
- Ensure you can connect to each of the hosts
- Ensure the VMs can ping each other
- Ensure the worker nodes have Docker installed on them
  > `sudo docker version`

## Troubleshooting Tips

If any of the VMs failed to provision, or is not configured correct, delete the vms using the commands below and then follow the steps in `run.ps1` pertaining the failed vm.

```
multipass stop <vm>
multipass delete <vm>
```

Alternatively you can delete all hosts with the following

```
multipass stop --all
multipass delete --all
multipass purge
```

Next: [Client Tools](03-client-tools.md)
