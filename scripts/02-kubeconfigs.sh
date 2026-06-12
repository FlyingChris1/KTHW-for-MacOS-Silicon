#!/usr/bin/env bash
set -euo pipefail

echo "===== 02 - Kubeconfigs ====="

cd ~

API_SERVER="172.22.5.11"

K8S_VERSION="v1.34.1"

if ! command -v kubectl >/dev/null 2>&1; then
  cd /tmp
  curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/arm64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  cd ~
fi

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

echo "Kubeconfigs created successfully."