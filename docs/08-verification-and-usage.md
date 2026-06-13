# 08 - Verification and Usage

After all components are installed, verify that the cluster is working.

Run all commands on `controller-1`.

## Verify nodes

```bash
kubectl get nodes
```

Expected:

```text
NAME           STATUS   ROLES    AGE   VERSION
controller-1   Ready    <none>   ...   v1.34.1
worker-1       Ready    <none>   ...   v1.34.1
worker-2       Ready    <none>   ...   v1.34.1
```

## Verify system pods

```bash
kubectl get pods -A
```

Expected:

```text
kube-system   calico-node-...
kube-system   calico-kube-controllers-...
```

The pods should eventually become `Running`.

## Verify cluster info

```bash
kubectl cluster-info
```

Expected:

```text
Kubernetes control plane is running at https://172.22.5.11:6443
```

## Test a workload

Create a test deployment:

```bash
kubectl create deployment nginx --image=nginx
```

Check the pod:

```bash
kubectl get pods -o wide
```

Expected:

```text
nginx-...   Running
```

Delete the deployment:

```bash
kubectl delete deployment nginx
```

## Useful debugging commands

Check kubelet:

```bash
sudo systemctl status kubelet --no-pager
sudo journalctl -u kubelet -n 80 --no-pager -l
```

Check kube-proxy:

```bash
sudo systemctl status kube-proxy --no-pager
sudo journalctl -u kube-proxy -n 80 --no-pager -l
```

Check API server:

```bash
sudo systemctl status kube-apiserver --no-pager
sudo journalctl -u kube-apiserver -n 80 --no-pager -l
```

Check etcd:

```bash
sudo systemctl status etcd --no-pager
sudo journalctl -u etcd -n 80 --no-pager -l
```

## Cleanup

On your host machine:

```bash
multipass stop --all
multipass delete --all
multipass purge
```
