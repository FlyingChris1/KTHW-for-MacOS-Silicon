> This tutorial is a modified version of the two repositories
> - [kelseyhightower/kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
> - [mmumshad/kubernetes-the-hard-way](https://github.com/mmumshad/kubernetes-the-hard-way)

# Kubernetes The Hard Way On Multipass

This tutorial walks you through setting up Kubernetes the Hard Way on a local machine using Multipass. 
Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

> This tutorial is for educational purposes only! Don't run this in production :)

## Target Audience

This tutorial is for those wanting to try kubernetes-the-hard-way but using their local machine instead of GCP or any other cloud provider. It is also intended to teach you the inner workings of a kubernetes cluster and all of its components. 

## Cluster Details

Kubernetes The Hard Way guides you through bootstrapping a highly available Kubernetes cluster with end-to-end encryption between components and RBAC authentication.

* [Kubernetes](https://github.com/kubernetes/kubernetes) 1.23.4
* [Docker Container Runtime](https://docs.docker.com/) 20.10.13
* [etcd](https://github.com/coreos/etcd) 3.5.2
* [Calico](https://projectcalico.docs.tigera.io/about/about-calico) 3.22
* [CoreDNS](https://github.com/coredns/coredns) coredns/coredns:1.9.0

## Labs

* [Prerequisites](docs/01-prerequisites.md)
* [Provisioning Compute Resources](docs/02-compute-resources.md)
* [Installing the Client Tools](docs/03-client-tools.md)
* [Provisioning the CA and Generating TLS Certificates](docs/04-certificate-authority.md)
* [Generating Kubernetes Configuration Files for Authentication](docs/05-kubernetes-configuration-files.md)
* [Generating the Data Encryption Config and Key](docs/06-data-encryption-keys.md)
* [Bootstrapping the etcd Cluster](docs/07-bootstrapping-etcd.md)
* [Bootstrapping the Kubernetes Control Plane](docs/08-bootstrapping-kubernetes-controllers.md)
* [Bootstrapping the Kubernetes Worker Nodes](docs/09-bootstrapping-kubernetes-workers.md)
* [TLS Bootstrapping the Kubernetes Worker Nodes](docs/10-tls-bootstrapping-kubernetes-workers.md)
* [Configuring kubectl for Remote Access](docs/11-configuring-kubectl.md)
* [Deploy Calico - Pod Networking Solution](docs/12-configure-pod-networking.md)
* [Kube API Server to Kubelet Configuration](docs/13-kube-apiserver-to-kubelet.md)
* [Deploying the DNS Cluster Add-on](docs/14-dns-addon.md)
* [Smoke Test](docs/15-smoke-test.md)

## Difference to the Other Tutorials
1. Uses Multipass to orchestrate the local virtual machines
2. Cluster Architecture
   - 2 Control Plane Nodes
   - 2 Worker Nodes
   - 1 Loadbalancer
3. Configure worker-1 manually and worker-2 using TLS Bootstrapping
4. Statically assigned IPs on private network
5. Uses openssl to generate certificates
6. Uses Calico for pod networking
7. Uses latest versions for the different components (at the time of making)
8. Some of the startup arguments for the kubelet have become depreciated and have been moved to kubelet-config.yaml
# kubernetes-the-hard-way-with-Multipass
# kubernetes-the-hard-way-with-Multipass
