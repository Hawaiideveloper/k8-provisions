#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -euxo pipefail

# Remove Cloud init
cloud-init status

sudo systemctl disable cloud-init
sudo systemctl mask cloud-init

sudo touch /etc/cloud/cloud-init.disabled

sudo cloud-init clean

sudo apt purge cloud-init -y
sudo rm -rf /etc/cloud /var/lib/cloud


# Kubernetes Version Configuration
KUBERNETES_VERSION="v1.30"
CRIO_VERSION="v1.30"
KUBERNETES_INSTALL_VERSION="1.30.0-1.1"

# Set Hostname
HOSTNAME="k8-controlplane"
echo "Setting hostname to '$HOSTNAME'..."
sudo hostnamectl set-hostname $HOSTNAME

# Load necessary kernel modules
echo "Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl params required by setup, params persist across reboots
echo "Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Apply sysctl parameters
sudo sysctl --system

# Disable swap and ensure it remains disabled
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

# Update system packages
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install necessary dependencies
echo "Installing dependencies..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg jq software-properties-common

# Install CRI-O runtime
echo "Installing CRI-O runtime..."
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

echo "CRI-O runtime installed successfully."

# Install kubelet, kubectl, and kubeadm
echo "Installing kubelet, kubeadm, and kubectl..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_INSTALL_VERSION" kubectl="$KUBERNETES_INSTALL_VERSION" kubeadm="$KUBERNETES_INSTALL_VERSION"
sudo apt-mark hold kubelet kubeadm kubectl

echo "kubelet, kubeadm, and kubectl installed successfully."

# Configure kubelet with node IP
echo "Configuring kubelet with node IP..."
NODE_IP=$(ip --json addr show ens34 | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')
echo "KUBELET_EXTRA_ARGS=--node-ip=$NODE_IP" | sudo tee /etc/default/kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Configure DNS
echo "Configuring DNS to use 172.100.55.2..."
cat <<EOF | sudo tee /etc/resolv.conf
nameserver 172.100.55.2
EOF

# Verify routing table
echo "Current routing table:"
ip route show

# Pre-pull Kubernetes images
echo "Pre-pulling Kubernetes images..."
sudo kubeadm config images pull

# Initialize Kubernetes control plane
echo "Initializing Kubernetes control plane..."
sudo kubeadm init --pod-network-cidr=192.168.79.0/24 --kubernetes-version="$KUBERNETES_INSTALL_VERSION" --apiserver-advertise-address=$NODE_IP

# Configure kubectl for the current user
echo "Configuring kubectl for current user..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify Kubernetes API server
echo "Verifying Kubernetes API server..."
if ! netstat -tuln | grep -q 6443; then
    echo "Kubernetes API server is not running. Check kubelet logs for details."
    sudo journalctl -xeu kubelet
    exit 1
fi

echo "Control plane setup is complete."
echo "Use the following commands to verify the setup:"
echo "kubectl get nodes"
echo "kubectl get pods -n kube-system"

echo "Join worker nodes to the cluster using the following command:"
sudo kubeadm token create --print-join-command

# Configure kubectl for the current user
echo "Configuring kubectl for current user..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config