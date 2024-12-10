#!/bin/bash

# Set hostname
sudo hostnamectl set-hostname k8s-control

# Load necessary kernel modules
cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
cat << EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

# Install containerd
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# Disable swap
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

# Add Kubernetes APT repository
sudo apt-get install -y apt-transport-https curl
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet=1.31.2-1.1 kubeadm=1.31.2-1.1 kubectl=1.31.2-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Clean up multiple default gateways
sudo ip route del default via 192.168.69.1 dev ens36
sudo ip route del default via 192.168.79.1 dev ens35

# Confirm default gateway
ip route show


sudo systemctl restart systemd-resolved

# Verify DNS resolution
resolvectl status
nslookup google.com

# Initialize Kubernetes with Pod Network CIDR
sudo kubeadm init --pod-network-cidr=192.168.79.0/24 --kubernetes-version v1.31.2

# Configure kubectl for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico networking
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

# Update Calico IP pool to match Pod Network CIDR
kubectl patch ippool default-ipv4-ippool \
  -n kube-system \
  --type='merge' \
  -p '{"spec":{"cidr":"192.168.79.0/24"}}'


# Display join command for worker nodes
kubeadm token create --print-join-command

# Final Confirmation of Setup
echo "Kubernetes setup complete. Verify using the following commands:"
echo "kubectl get nodes"
echo "kubectl get pods -n kube-system"
