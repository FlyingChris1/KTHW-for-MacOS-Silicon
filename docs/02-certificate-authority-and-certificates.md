# 02 - Certificate Authority and Certificates

All Kubernetes components communicate using TLS certificates.

Run all commands on `controller-1`.

## Create the Certificate Authority

```bash
cd ~

cat > ca-openssl.cnf <<'EOF'
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
CN = KUBERNETES-CA

[ v3_ca ]
basicConstraints = critical, CA:true
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

openssl genrsa -out ca.key 2048

openssl req -x509 -new -nodes -key ca.key \
  -sha256 -days 365 \
  -out ca.crt \
  -config ca-openssl.cnf

openssl x509 -in ca.crt -noout -subject
```

## Create admin and control plane certificates

```bash
cd ~

# admin
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -out admin.csr -subj "/CN=admin/O=system:masters"
openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out admin.crt -days 365

# kube-controller-manager
openssl genrsa -out kube-controller-manager.key 2048
openssl req -new -key kube-controller-manager.key -out kube-controller-manager.csr -subj "/CN=system:kube-controller-manager"
openssl x509 -req -in kube-controller-manager.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-controller-manager.crt -days 365

# kube-scheduler
openssl genrsa -out kube-scheduler.key 2048
openssl req -new -key kube-scheduler.key -out kube-scheduler.csr -subj "/CN=system:kube-scheduler"
openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-scheduler.crt -days 365

# kube-proxy
openssl genrsa -out kube-proxy.key 2048
openssl req -new -key kube-proxy.key -out kube-proxy.csr -subj "/CN=system:kube-proxy"
openssl x509 -req -in kube-proxy.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-proxy.crt -days 365
```

## Create node certificates

```bash
cd ~

for node in controller-1 worker-1 worker-2; do
  case "$node" in
    controller-1) NODE_IP="172.22.5.11" ;;
    worker-1) NODE_IP="172.22.5.21" ;;
    worker-2) NODE_IP="172.22.5.22" ;;
  esac

  openssl genrsa -out ${node}.key 2048

  openssl req -new \
    -key ${node}.key \
    -out ${node}.csr \
    -subj "/CN=system:node:${node}/O=system:nodes"

  cat > openssl-${node}.cnf <<EOF
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = DNS:${node},IP:${NODE_IP}
EOF

  openssl x509 -req \
    -in ${node}.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -out ${node}.crt \
    -days 365 \
    -extensions v3_req \
    -extfile openssl-${node}.cnf
done
```

## Create kube-apiserver certificate

```bash
cd ~

cat > openssl-apiserver.cnf <<'EOF'
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = controller-1
IP.1 = 10.96.0.1
IP.2 = 172.22.5.11
IP.3 = 127.0.0.1
EOF

openssl genrsa -out kube-apiserver.key 2048

openssl req -new \
  -key kube-apiserver.key \
  -out kube-apiserver.csr \
  -subj "/CN=kube-apiserver"

openssl x509 -req \
  -in kube-apiserver.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out kube-apiserver.crt \
  -days 365 \
  -extensions v3_req \
  -extfile openssl-apiserver.cnf
```

## Create etcd certificate

```bash
cd ~

cat > openssl-etcd.cnf <<'EOF'
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = controller-1
IP.1 = 172.22.5.11
IP.2 = 127.0.0.1
EOF

openssl genrsa -out etcd-server.key 2048
openssl req -new -key etcd-server.key -out etcd-server.csr -subj "/CN=etcd-server"

openssl x509 -req \
  -in etcd-server.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out etcd-server.crt \
  -days 365 \
  -extensions v3_req \
  -extfile openssl-etcd.cnf
```

## Create service account certificate

```bash
cd ~

openssl genrsa -out service-account.key 2048

openssl req -new \
  -key service-account.key \
  -out service-account.csr \
  -subj "/CN=service-accounts"

openssl x509 -req \
  -in service-account.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out service-account.crt \
  -days 365
```

## Verify certificates

```bash
openssl verify -CAfile ca.crt \
  admin.crt \
  kube-controller-manager.crt \
  kube-scheduler.crt \
  kube-proxy.crt \
  controller-1.crt \
  worker-1.crt \
  worker-2.crt \
  kube-apiserver.crt \
  etcd-server.crt \
  service-account.crt
```

Every certificate should return `OK`.

### [Next step](03-kubeconfigs-and-encryption.md)
