#!/usr/bin/env bash
set -euo pipefail

echo "===== 07 - Calico ====="

cd ~

CALICO_VERSION="v3.30.2"

curl -LO "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml"

sed -i 's#192.168.0.0/16#10.142.0.0/24#g' calico.yaml

kubectl apply -f calico.yaml --kubeconfig ~/admin.kubeconfig

echo "Waiting for nodes to become Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s --kubeconfig ~/admin.kubeconfig

echo "Calico installed successfully."