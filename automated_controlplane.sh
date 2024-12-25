#!/bin/bash

# Exit immediately if a command fails
set -e

# Ensure required tools are installed
echo "Installing required tools..."
sudo apt-get update -y
sudo apt-get install -y curl apt-transport-https ca-certificates gnupg software-properties-common qemu qemu-kvm
sudo apt-get install -y containerd


# Remove any incorrect Kubernetes repository configurations
echo "Removing incorrect Kubernetes repository configuration..."
sudo rm -f /etc/apt/sources.list.d/kubernetes.list

# Add Kubernetes repository
echo "Adding Kubernetes repository..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list


# Update and install Kubernetes tools
echo "Updating and installing Kubernetes tools..."
sudo apt-get update
K8S_VERSION="1.31.4-1.1"  # most sable kubernetes version that works wirh calico 
sudo apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION
sudo apt-mark hold kubelet kubeadm kubectl


# We need to restart all services
sleep 3
echo "you should say yes to restarting all services"


# If we dont get the apt-get to work try this:
# curl -LO "https://dl.k8s.io/release/v1.31.2/bin/linux/amd64/kubectl"
# curl -LO "https://dl.k8s.io/release/v1.31.2/bin/linux/amd64/kubeadm"
# curl -LO "https://dl.k8s.io/release/v1.31.2/bin/linux/amd64/kubelet"
# chmod +x kubectl kubeadm kubelet

# sudo mv kubectl kubeadm kubelet /usr/local/bin/

# kubectl version --client
# kubeadm version
# kubelet --version


# Disable swap (Kubernetes requires swap to be off)
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Initialize Kubernetes control plane
echo "Initializing Kubernetes control plane..."
POD_NETWORK_CIDR="192.168.79.0/24"
sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version=$K8S_VERSION

# Set up kubeconfig for the current user
echo "Setting up kubeconfig..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico network plugin
echo "Installing Calico network plugin..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml


# Debug Repo Issue and clear old configurations
echo "clear old configs"
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update

# Suro re-add repo
echo "re-adding repo"
sudo rm /etc/apt/sources.list.d/kubernetes.list
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-main main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

# confirm no proxy is blocking us
sudo apt-get update
sudo apt-get install --only-upgrade curl openssl ca-certificates

curl -v https://apt.kubernetes.io/


# insert a wait
pause 
echo "you can skip the wait and reboot manually"
wait 360


# We need to reboot
sudo systemctl restart packagekit.service

sudo reboot

# Verify cluster nodes
echo "Verifying cluster nodes..."
kubectl get nodes
