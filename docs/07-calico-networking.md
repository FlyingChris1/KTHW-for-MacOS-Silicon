# 07 - Installing Calico Pod Networking

Kubernetes nodes remain `NotReady` until a CNI plugin is installed.

This setup uses Calico.

Run all commands on `controller-1`.

## Download Calico manifest

```bash
cd ~

curl -LO https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/calico.yaml
```

## Configure Pod CIDR

The cluster uses:

```text
10.142.0.0/24
```

Update the default Calico CIDR:

```bash
sed -i 's#192.168.0.0/16#10.142.0.0/24#g' calico.yaml
```

## Apply Calico

```bash
kubectl apply -f calico.yaml
```

## Wait for nodes

```bash
kubectl wait --for=condition=Ready nodes --all --timeout=300s
```

## Verify pods

```bash
kubectl get pods -n kube-system -o wide
```

Expected pods:

```text
calico-node
calico-kube-controllers
```

They may take one or two minutes to become fully `Running`.

## Verify nodes

```bash
kubectl get nodes
```

Expected:

```text
controller-1   Ready
worker-1       Ready
worker-2       Ready
```

### [Next step](08-verification-and-usage.md)
