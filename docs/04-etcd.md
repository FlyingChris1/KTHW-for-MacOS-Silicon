# 04 - Bootstrapping etcd

etcd stores all Kubernetes cluster state.

In this setup, etcd runs as a single-node etcd instance on `controller-1`.

Run all commands on `controller-1`.

## Install etcd

```bash
cd /tmp

curl -LO https://github.com/etcd-io/etcd/releases/download/v3.6.4/etcd-v3.6.4-linux-arm64.tar.gz

tar -xzf etcd-v3.6.4-linux-arm64.tar.gz

sudo mv etcd-v3.6.4-linux-arm64/etcd /usr/local/bin/
sudo mv etcd-v3.6.4-linux-arm64/etcdctl /usr/local/bin/
sudo mv etcd-v3.6.4-linux-arm64/etcdutl /usr/local/bin/
```

Verify:

```bash
etcd --version
etcdctl version
```

## Configure etcd

```bash
cd ~

sudo mkdir -p /etc/etcd /var/lib/etcd

sudo cp ca.crt etcd-server.crt etcd-server.key /etc/etcd/

sudo chmod 600 /etc/etcd/etcd-server.key
```

## Create systemd service

```bash
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
```

## Start etcd

```bash
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

## Verify etcd

```bash
sudo systemctl status etcd --no-pager

sudo etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key
```

Expected output should show `controller-1` as a started etcd member.

### [Next step](05-control-plane.md)
