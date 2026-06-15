$ErrorActionPreference = "Stop"

$VMs = @(
    "controller-1",
    "worker-1",
    "worker-2"
)

function Wait-ForMultipassSSH {
    param (
        [string]$Name,
        [int]$TimeoutSeconds = 240
    )

    Write-Host "Waiting for Multipass SSH on $Name"

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
        try {
            multipass exec $Name -- true 2>$null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "$Name is reachable"
                return
            }
        } catch {
            Start-Sleep -Seconds 5
        }

        Start-Sleep -Seconds 5
    }

    throw "Timed out waiting for Multipass SSH on $Name"
}

function Run-Multipass {
    param (
        [string[]]$Arguments
    )

    & multipass @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "multipass $($Arguments -join ' ') failed"
    }
}

Write-Host "Starting VMs"

Run-Multipass @(
    "launch",
    "--cloud-init", "controller-cloud-config.yml",
    "--disk", "10G",
    "--memory", "3G",
    "--cpus", "2",
    "--name", "controller-1"
)

Run-Multipass @(
    "launch",
    "--cloud-init", "worker-cloud-config.yml",
    "--disk", "15G",
    "--memory", "3G",
    "--cpus", "1",
    "--name", "worker-1"
)

Run-Multipass @(
    "launch",
    "--cloud-init", "worker-cloud-config.yml",
    "--disk", "15G",
    "--memory", "3G",
    "--cpus", "1",
    "--name", "worker-2"
)

Write-Host ""
Write-Host "Waiting for VMs to become reachable"

foreach ($vm in $VMs) {
    Wait-ForMultipassSSH -Name $vm
}

Write-Host ""
Write-Host "Copying netplan yaml"

Run-Multipass @("transfer", "01-controller-1-network.yaml", "controller-1`:01-controller-1-network.yaml")
Run-Multipass @("transfer", "01-worker-1-network.yaml", "worker-1`:01-worker-1-network.yaml")
Run-Multipass @("transfer", "01-worker-2-network.yaml", "worker-2`:01-worker-2-network.yaml")

Write-Host ""
Write-Host "Installing netplan configs"

Run-Multipass @("exec", "controller-1", "--", "sudo", "cp", "01-controller-1-network.yaml", "/etc/netplan/99-kubernetes.yaml")
Run-Multipass @("exec", "worker-1", "--", "sudo", "cp", "01-worker-1-network.yaml", "/etc/netplan/99-kubernetes.yaml")
Run-Multipass @("exec", "worker-2", "--", "sudo", "cp", "01-worker-2-network.yaml", "/etc/netplan/99-kubernetes.yaml")

foreach ($vm in $VMs) {
    Run-Multipass @("exec", $vm, "--", "sudo", "chmod", "600", "/etc/netplan/99-kubernetes.yaml")
}

Write-Host ""
Write-Host "Applying netplan"

foreach ($vm in $VMs) {
    Write-Host "Applying netplan on $vm"

    Run-Multipass @("exec", $vm, "--", "sudo", "netplan", "generate")
    Run-Multipass @("exec", $vm, "--", "sudo", "netplan", "apply")

    Start-Sleep -Seconds 10
}

Write-Host ""
Write-Host "Waiting for VMs after netplan apply"

foreach ($vm in $VMs) {
    Wait-ForMultipassSSH -Name $vm
}

Write-Host ""
Write-Host "Writing /etc/hosts entries"

foreach ($vm in $VMs) {
    Run-Multipass @(
        "exec", $vm, "--",
        "bash", "-lc",
        "sudo tee -a /etc/hosts >/dev/null <<'EOF'
172.22.5.11 controller-1
172.22.5.21 worker-1
172.22.5.22 worker-2
EOF"
    )
}

Write-Host ""
Write-Host "Preparing SSH from controller-1 to workers"

Run-Multipass @(
    "exec", "controller-1", "--",
    "bash", "-lc",
    "mkdir -p ~/.ssh && chmod 700 ~/.ssh && if [ ! -f ~/.ssh/id_ed25519 ]; then ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519; fi"
)

$ControllerPublicKey = & multipass exec controller-1 -- bash -lc "cat ~/.ssh/id_ed25519.pub"

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($ControllerPublicKey)) {
    throw "Could not read controller-1 public SSH key"
}

$ControllerPublicKey = $ControllerPublicKey.Trim()
$EscapedKey = $ControllerPublicKey.Replace("'", "'\''")

foreach ($worker in @("worker-1", "worker-2")) {
    Write-Host "Installing controller-1 public key on $worker"

    Run-Multipass @(
        "exec", $worker, "--",
        "bash", "-lc",
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
    )

    Run-Multipass @(
        "exec", $worker, "--",
        "bash", "-lc",
        "touch ~/.ssh/authorized_keys && grep -qxF '$EscapedKey' ~/.ssh/authorized_keys || echo '$EscapedKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    )
}

Write-Host ""
Write-Host "Adding workers to controller-1 known_hosts"

Run-Multipass @(
    "exec", "controller-1", "--",
    "bash", "-lc",
    "ssh-keyscan -H worker-1 worker-2 >> ~/.ssh/known_hosts 2>/dev/null || true"
)

Write-Host ""
Write-Host "Testing SSH"

Run-Multipass @("exec", "controller-1", "--", "ssh", "worker-1", "hostname")
Run-Multipass @("exec", "controller-1", "--", "ssh", "worker-2", "hostname")

Write-Host ""
Write-Host "VM Status"
multipass list

Write-Host ""
Write-Host "Controller-1 IPs"
Run-Multipass @("exec", "controller-1", "--", "ip", "addr", "show", "enp0s1")

Write-Host ""
Write-Host "Done. Next:"
Write-Host "multipass shell controller-1"
Write-Host "cd ~/kubernetes-the-hard-way"
Write-Host "bash scripts/install-all.sh"