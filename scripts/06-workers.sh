#!/usr/bin/env bash
set -euo pipefail

echo "===== 06 - Nodes / Workers ====="

cd ~

K8S_VERSION="v1.34.1"
NODES=("controller-1" "worker-1" "worker-2")

configure_node() {
  local node="$1"

  echo "===== Configuring ${node} ====="

  if [ "$node" = "controller-1" ]; then
    RUN=""
  else
    RUN="ssh ${node}"
    scp ca.crt ${node}.crt ${node}.key ${node}.kubeconfig kube-proxy.kubeconfig ${node}:~
  fi

  $RUN bash <<EOF
set -euo pipefail

sudo tee -a /etc/hosts >/dev/null <<HOSTS
172.22.5.11 controller-1
172.22.5.21 worker-1
172.22.5.22 worker-2
HOSTS

sudo apt update
sudo apt install -y containerd runc

cd /tmp

if ! command -v kubelet >/dev/null 2>&1; then
  curl -LO https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/arm64/kubelet
  chmod +x kubelet
  sudo mv kubelet /usr/local/bin/
fi

if ! command -v kube-proxy >/dev/null 2>&1; then
  curl -LO https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/arm64/kube-proxy
  chmod +x kube-proxy
  sudo mv kube-proxy /usr/local/bin/
fi

cd ~

sudo mkdir -p /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes /etc/cni/net.d /opt/cni/bin

sudo cp ca.crt /var/lib/kubernetes/
sudo cp ${node}.crt /var/lib/kubelet/kubelet.crt
sudo cp ${node}.key /var/lib/kubelet/kubelet.key
sudo cp ${node}.kubeconfig /var/lib/kubelet/kubeconfig
sudo cp kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
sudo chmod 600 /var/lib/kubelet/kubelet.key

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i "s/SystemdCgroup = false/SystemdCgroup = true/" /etc/containerd/config.toml

cat <<KUBELET | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: /var/lib/kubernetes/ca.crt
authorization:
  mode: Webhook
clusterDomain: cluster.local
clusterDNS:
  - 10.96.0.10
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock
registerNode: true
resolvConf: /run/systemd/resolve/resolv.conf
runtimeRequestTimeout: 15m
tlsCertFile: /var/lib/kubelet/kubelet.crt
tlsPrivateKeyFile: /var/lib/kubelet/kubelet.key
KUBELET

cat <<PROXY | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: /var/lib/kube-proxy/kubeconfig
mode: iptables
clusterCIDR: 10.142.0.0/24
PROXY

cat <<SERVICE | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

cat <<SERVICE | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable containerd kubelet kube-proxy
sudo systemctl restart containerd
sudo systemctl restart kubelet kube-proxy
EOF
}

for node in "${NODES[@]}"; do
  configure_node "$node"
done

cat <<EOF | kubectl apply --kubeconfig ~/admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-proxy
subjects:
- kind: User
  name: system:kube-proxy
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:node-proxier
  apiGroup: rbac.authorization.k8s.io
EOF

sleep 10

kubectl get nodes --kubeconfig ~/admin.kubeconfig

echo "Node installation complete."