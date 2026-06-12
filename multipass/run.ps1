$ErrorActionPreference = "Stop"

$VMs = @(
    "controller-1",
    "worker-1",
    "worker-2"
)

Write-Host "Starting VMs"

multipass launch --cloud-init controller-cloud-config.yml --disk 10G --memory 3G --cpus 2 --name controller-1
Start-Sleep -Seconds 20

multipass launch --cloud-init worker-cloud-config.yml --disk 15G --memory 3G --cpus 1 --name worker-1
Start-Sleep -Seconds 20

multipass launch --cloud-init worker-cloud-config.yml --disk 15G --memory 3G --cpus 1 --name worker-2
Start-Sleep -Seconds 30

Write-Host "Copying netplan yaml"

multipass transfer 01-controller-1-network.yaml controller-1`:01-controller-1-network.yaml
multipass transfer 01-worker-1-network.yaml worker-1`:01-worker-1-network.yaml
multipass transfer 01-worker-2-network.yaml worker-2`:01-worker-2-network.yaml

Write-Host "Installing netplan configs"

multipass exec controller-1 -- sudo cp 01-controller-1-network.yaml /etc/netplan/99-kubernetes.yaml
multipass exec worker-1 -- sudo cp 01-worker-1-network.yaml /etc/netplan/99-kubernetes.yaml
multipass exec worker-2 -- sudo cp 01-worker-2-network.yaml /etc/netplan/99-kubernetes.yaml

Write-Host "Applying netplan"

foreach ($vm in $VMs) {
    Write-Host "Applying netplan on $vm"

    multipass exec $vm -- sudo netplan generate
    multipass exec $vm -- sudo netplan apply

    Start-Sleep -Seconds 10
}

Write-Host "Writing /etc/hosts entries"

foreach ($vm in $VMs) {
    multipass exec $vm -- bash -lc "sudo tee -a /etc/hosts >/dev/null <<'EOF'
172.22.5.11 controller-1
172.22.5.21 worker-1
172.22.5.22 worker-2
EOF"
}

Write-Host "Preparing SSH from controller-1 to workers"

multipass exec controller-1 -- bash -lc "mkdir -p ~/.ssh && chmod 700 ~/.ssh && if [ ! -f ~/.ssh/id_ed25519 ]; then ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519; fi"

$ControllerPublicKey = multipass exec controller-1 -- bash -lc "cat ~/.ssh/id_ed25519.pub"

foreach ($worker in @("worker-1", "worker-2")) {
    Write-Host "Installing controller-1 public key on $worker"

    multipass exec $worker -- bash -lc "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

    $EscapedKey = $ControllerPublicKey.Replace("'", "'\''")

    multipass exec $worker -- bash -lc "grep -qxF '$EscapedKey' ~/.ssh/authorized_keys 2>/dev/null || echo '$EscapedKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
}

Write-Host "Adding workers to controller-1 known_hosts"

multipass exec controller-1 -- bash -lc "ssh-keyscan -H worker-1 worker-2 >> ~/.ssh/known_hosts 2>/dev/null || true"

Write-Host ""
Write-Host "Testing SSH"

multipass exec controller-1 -- ssh worker-1 hostname
multipass exec controller-1 -- ssh worker-2 hostname

Write-Host ""
Write-Host "VM Status"
multipass list

Write-Host ""
Write-Host "Controller-1 IPs"
multipass exec controller-1 -- ip addr show enp0s1

Write-Host ""
Write-Host "Done. Next:"
Write-Host "multipass shell controller-1"
Write-Host "cd ~/kubernetes-the-hard-way"
Write-Host "bash scripts/install-all.sh"