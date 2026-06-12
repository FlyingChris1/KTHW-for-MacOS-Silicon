#!/usr/bin/env bash
set -euo pipefail

echo "===== 99 - Verify ====="

kubectl get nodes --kubeconfig ~/admin.kubeconfig
echo
kubectl get pods -A --kubeconfig ~/admin.kubeconfig
echo
kubectl cluster-info --kubeconfig ~/admin.kubeconfig

echo
echo "Verification complete."