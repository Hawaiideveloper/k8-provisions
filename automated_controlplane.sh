#!/bin/bash

# Exit immediately if a command fails
set -e

# Ensure required tools are installed
echo "Installing required tools..."
sudo apt-get update -y
sudo apt-get install -y curl apt-transport-https ca-certificates 
software-properties-common

# Remove any incorrect repository configurations
echo "Removing incorrect Kubernetes repository configuration..."
sudo rm -f /etc/apt/sources.list.d/kubernetes.list

# Add Kubernetes repository
echo "Adding Kubernetes repository..."
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | 
sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] 
https://apt.kubernetes.io/ kubernetes-main main" | sudo tee 
/etc/apt/sources.list.d/kubernetes.list

# Update and install Kubernetes tools
echo "Updating and installing Kubernetes tools..."
sudo apt-get update
K8S_VERSION="1.31.2"  # Replace with your desired Kubernetes version
sudo apt-get install -y kubelet=${K8S_VERSION}-00 
kubeadm=${K8S_VERSION}-00 kubectl=${K8S_VERSION}-00
sudo apt-mark hold kubelet kubeadm kubectl

# Disable swap (Kubernetes requires swap to be off)
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Initialize Kubernetes control plane
echo "Initializing Kubernetes control plane..."
POD_NETWORK_CIDR="192.168.79.0/24"
sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR 
--kubernetes-version=${K8S_VERSION}

# Set up kubeconfig for the current user
echo "Setting up kubeconfig..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico network plugin
echo "Installing Calico network plugin..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Verify cluster nodes
echo "Verifying cluster nodes..."
kubectl get nodes

