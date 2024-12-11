#!/bin/bash




# Exit if any command fails
set -e

# Set hostname
echo "Setting hostname to 'k8-controlplane'..."
sudo hostnamectl set-hostname k8-controlplane

# Load necessary kernel modules
echo "Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
echo "Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

# Install and configure containerd
echo "Installing containerd..."
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's|sandbox_image = .*|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Install net-tools (for netstat)
echo "Installing net-tools for netstat..."
sudo apt-get install -y net-tools

# Disable swap
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Add Kubernetes APT repository
echo "Adding Kubernetes APT repository..."
sudo apt-get install -y apt-transport-https curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

# Install kubelet, kubeadm, and kubectl
echo "Installing kubelet, kubeadm, and kubectl (v1.31.2-1.1)..."
sudo apt-get install -y kubelet=1.31.2-1.1 kubeadm=1.31.2-1.1 kubectl=1.31.2-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Pre-pull required images for kubeadm
echo "Pre-pulling Kubernetes images..."
sudo kubeadm config images pull

# Clean up multiple default gateways
echo "Removing conflicting default routes..."
sudo ip route del default via 192.168.69.1 dev ens36 || true
sudo ip route del default via 192.168.79.1 dev ens35 || true

# Confirm default gateway
echo "Current routing table:"
ip route show

# Restart systemd-resolved to ensure DNS resolution works
echo "Restarting systemd-resolved..."
sudo systemctl restart systemd-resolved

# Verify DNS resolution
echo "Verifying DNS resolution..."
if ! nslookup google.com; then
    echo "DNS resolution failed. Please check your network configuration."
    exit 1
fi

# Initialize Kubernetes with Pod Network CIDR
echo "Initializing Kubernetes control plane..."
sudo kubeadm init --pod-network-cidr=192.168.79.0/24 --kubernetes-version=v1.31.2 --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

# Configure kubectl for current user
echo "Configuring kubectl for the current user..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify Kubernetes API server
echo "Checking if Kubernetes API server is running..."
if ! netstat -tuln | grep -q 6443; then
    echo "Kubernetes API server is not running. Check kubelet logs for details."
    sudo journalctl -xeu kubelet
    exit 1
fi

# Verify kubelet service
echo "Checking if kubelet service is active..."
if ! sudo systemctl is-active --quiet kubelet; then
    echo "kubelet service is not running. Starting kubelet..."
    sudo systemctl start kubelet
fi

# Display join command for worker nodes
echo "Use the following command to join worker nodes to the cluster:"
sudo kubeadm token create --print-join-command

# Verification commands
echo "Control plane setup complete. Verify the setup using the following commands:"
echo "kubectl get nodes"
echo "kubectl get pods -n kube-system"
