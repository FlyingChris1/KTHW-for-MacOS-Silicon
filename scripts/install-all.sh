#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo " Kubernetes The Hard Way v1.34.1"
echo "========================================="
echo

echo "[1/9] Certificates"
bash scripts/01-certificates.sh

echo
echo "[2/8] Kubeconfigs"
bash scripts/02-kubeconfigs.sh

echo
echo "[3/8] Encryption"
bash scripts/03-encryption.sh

echo
echo "[4/8] etcd"
bash scripts/04-etcd.sh

echo
echo "[5/8] Control Plane"
bash scripts/05-control-plane.sh

echo
echo "[6/8] Workers"
bash scripts/06-workers.sh

echo
echo "[7/8] Calico"
bash scripts/07-calico.sh

echo
echo "[8/8] Verification"
bash scripts/99-verify.sh

echo
echo "========================================="
echo " Installation completed"
echo "========================================="
