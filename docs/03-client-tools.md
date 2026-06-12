# Installing the Client Tools

First identify a system from where you will perform administrative tasks, such as creating certificates, kubeconfig files and distributing them to the different VMs.

If you are on a Linux laptop, then your laptop could be this system. In my case I chose the `controller-1` node to perform administrative tasks. Whichever system you chose make sure that system is able to access all the provisioned VMs through SSH to copy files over.

## Access all VMs

Generate Key Pair on `controller-1` node

```
ssh-keygen
```

Leave all settings to default.

View the generated public key ID at:

```
cat .ssh/id_red25519.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD......8+08b ubuntu@controller-1
```

Move public key of controller-1 to all other VMs. Access each VM using the following multipass command

```
multipass shell controller-2
```

Then add public key from controller-1 to the authorized keys for all hosts (including controller-1)

```
cat >> ~/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD......8+08b ubuntu@controller-1
EOF
```

## Install kubectl

The [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl). command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

Reference: [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### Linux

On `controller-1`

```
curl -LO https://dl.k8s.io/release/v1.23.4/bin/linux/arm64/kubectl
```

```
chmod +x kubectl
```

```
sudo mv kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` version 1.23.4 or higher is installed:

```
kubectl version --client
```

> output

```
Client Version: version.Info{Major:"1", Minor:"23", GitVersion:"v1.23.4", GitCommit:"e6c093d87ea4cbb530a7b2ae91e54c0842d8308a", GitTreeState:"clean", BuildDate:"2022-02-16T12:38:05Z", GoVersion:"go1.17.7", Compiler:"gc", 
Platform:"linux/arm"}
```

Next: [Certificate Authority](04-certificate-authority.md)
