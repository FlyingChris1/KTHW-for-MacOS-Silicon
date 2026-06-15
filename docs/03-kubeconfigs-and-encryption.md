# 03 - Kubeconfigs and Encryption Configuration

Kubeconfig files define how Kubernetes components authenticate to the API server.

Run all commands on `controller-1`.

## Create node kubeconfigs

```bash
cd ~

API_SERVER="172.22.5.11"

for node in controller-1 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${API_SERVER}:6443 \
    --kubeconfig=${node}.kubeconfig

  kubectl config set-credentials system:node:${node} \
    --client-certificate=${node}.crt \
    --client-key=${node}.key \
    --embed-certs=true \
    --kubeconfig=${node}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${node} \
    --kubeconfig=${node}.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${node}.kubeconfig
done
```

## Create component kubeconfigs

```bash
cd ~

API_SERVER="172.22.5.11"

for user in kube-proxy kube-controller-manager kube-scheduler admin; do
  if [ "$user" = "admin" ]; then
    USER_NAME="admin"
  else
    USER_NAME="system:${user}"
  fi

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${API_SERVER}:6443 \
    --kubeconfig=${user}.kubeconfig

  kubectl config set-credentials "${USER_NAME}" \
    --client-certificate=${user}.crt \
    --client-key=${user}.key \
    --embed-certs=true \
    --kubeconfig=${user}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user="${USER_NAME}" \
    --kubeconfig=${user}.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${user}.kubeconfig
done
```

## Create encryption configuration

The API server uses this file to encrypt Kubernetes Secrets at rest.

```bash
cd ~

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfiguration
apiVersion: apiserver.config.k8s.io/v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

cat encryption-config.yaml
```

## Prepare controller files

```bash
sudo mkdir -p /var/lib/kubernetes

sudo cp ca.crt ca.key kube-apiserver.crt kube-apiserver.key service-account.crt service-account.key encryption-config.yaml /var/lib/kubernetes/

sudo cp kube-controller-manager.kubeconfig kube-scheduler.kubeconfig admin.kubeconfig /var/lib/kubernetes/

sudo chmod 600 /var/lib/kubernetes/*.key
```

## Copy worker files

```bash
scp ca.crt worker-1.crt worker-1.key worker-1.kubeconfig kube-proxy.kubeconfig worker-1:~

scp ca.crt worker-2.crt worker-2.key worker-2.kubeconfig kube-proxy.kubeconfig worker-2:~
```

## Verify copied files

```bash
ssh worker-1 "ls -l ca.crt worker-1.crt worker-1.key worker-1.kubeconfig kube-proxy.kubeconfig"

ssh worker-2 "ls -l ca.crt worker-2.crt worker-2.key worker-2.kubeconfig kube-proxy.kubeconfig"
```

### [Next step](04-etcd.md)