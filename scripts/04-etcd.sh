#!/usr/bin/env bash
set -euo pipefail

echo "===== 04 - etcd ====="

cd ~

ETCD_VERSION="v3.6.4"

if ! command -v etcd >/dev/null 2>&1; then
  cd /tmp

  curl -LO https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-arm64.tar.gz

  tar -xzf etcd-${ETCD_VERSION}-linux-arm64.tar.gz

  sudo mv etcd-${ETCD_VERSION}-linux-arm64/etcd /usr/local/bin/
  sudo mv etcd-${ETCD_VERSION}-linux-arm64/etcdctl /usr/local/bin/
  sudo mv etcd-${ETCD_VERSION}-linux-arm64/etcdutl /usr/local/bin/
fi

cd ~

sudo mkdir -p /etc/etcd
sudo mkdir -p /var/lib/etcd

sudo cp ca.crt /etc/etcd/
sudo cp etcd-server.crt /etc/etcd/
sudo cp etcd-server.key /etc/etcd/

sudo chmod 600 /etc/etcd/etcd-server.key

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name controller-1 \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://172.22.5.11:2380 \\
  --listen-peer-urls https://172.22.5.11:2380 \\
  --listen-client-urls https://172.22.5.11:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://172.22.5.11:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-1=https://172.22.5.11:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl restart etcd

sleep 5

sudo systemctl --no-pager --full status etcd

echo "etcd installation complete."