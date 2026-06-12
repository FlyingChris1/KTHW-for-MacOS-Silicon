$ErrorActionPreference = "Stop"

$VMs = @(
    "controller-1",
    "controller-2",
    "loadbalancer",
    "worker-1",
    "worker-2"
)

Write-Host "Starting VMs"

multipass launch --cloud-init controller-cloud-config.yml --disk 5G --memory 1G --cpus 1 --name controller-1
Start-Sleep -Seconds 20

multipass launch --cloud-init controller-cloud-config.yml --disk 5G --memory 1G --cpus 1 --name controller-2
Start-Sleep -Seconds 20

multipass launch --cloud-init controller-cloud-config.yml --disk 5G --memory 1G --cpus 1 --name loadbalancer
Start-Sleep -Seconds 20

multipass launch --cloud-init worker-cloud-config.yml --disk 5G --memory 5G --cpus 1 --name worker-1
Start-Sleep -Seconds 20

multipass launch --cloud-init worker-cloud-config.yml --disk 5G --memory 5G --cpus 1 --name worker-2
Start-Sleep -Seconds 30

Write-Host "Copying netplan yaml"

multipass transfer 01-controller-1-network.yaml controller-1`:01-controller-1-network.yaml
multipass transfer 01-controller-2-network.yaml controller-2`:01-controller-2-network.yaml
multipass transfer 01-loadbalancer-network.yaml loadbalancer`:01-loadbalancer-network.yaml
multipass transfer 01-worker-1-network.yaml worker-1`:01-worker-1-network.yaml
multipass transfer 01-worker-2-network.yaml worker-2`:01-worker-2-network.yaml

Write-Host "Installing netplan configs"

multipass exec controller-1 -- sudo cp 01-controller-1-network.yaml /etc/netplan/99-kubernetes.yaml
multipass exec controller-2 -- sudo cp 01-controller-2-network.yaml /etc/netplan/99-kubernetes.yaml
multipass exec loadbalancer -- sudo cp 01-loadbalancer-network.yaml /etc/netplan/99-kubernetes.yaml
multipass exec worker-1 -- sudo cp 01-worker-1-network.yaml /etc/netplan/99-kubernetes.yaml
multipass exec worker-2 -- sudo cp 01-worker-2-network.yaml /etc/netplan/99-kubernetes.yaml

Write-Host "Applying netplan"

foreach ($vm in $VMs) {
    Write-Host "Applying netplan on $vm"

    multipass exec $vm -- sudo netplan generate
    multipass exec $vm -- sudo netplan apply

    Start-Sleep -Seconds 10
}

Write-Host ""
Write-Host "VM Status"
multipass list

Write-Host ""
Write-Host "Controller-1 IPs"
multipass exec controller-1 -- ip addr show enp0s1