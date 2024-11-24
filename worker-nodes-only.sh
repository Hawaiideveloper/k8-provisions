#!/bin/bash


# Description: set up the worker nodes installer
# Author: Hawaiideveloper
# Date: 2024-11-03
# Version: 1.0
# Usage: ./worker-nodes-only.sh
# Notes: Additional details, if any
# This will require the token generated from control plane

# Add the Kubernetes Repository
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update




# Ensure Kubeadmn is installed
sudo snap install kubeadm --classic

# conntrack is a utility required by Kubernetes for network connection tracking.
sudo apt-get update
sudo apt-get install -y conntrack

# kubelet service must be installed and running on the worker node.
sudo snap install kubelet --classic


# Start and enable kubelet.service
sudo systemctl enable kubelet.service
sudo systemctl start kubelet.service

# Install Containerd
sudo apt-get install -y containerd


# Start and enable containerd
sudo systemctl enable containerd
sudo systemctl start containerd

# crictl utility is required for interacting with the container runtime.


# Fix ip_forward
sudo sysctl -w net.ipv4.ip_forward=1

# Make it permanent:
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Disable swap temporarily:
sudo swapoff -a


# Backup the original fstab file
sudo cp /etc/fstab /etc/fstab.bak

# Use sed to comment out the line referencing swap partition
sudo sed -i '/swap/s/^/#/' /etc/fstab

# Alternatively, use sed to remove the line referencing swap partition
# Uncomment the next line if you want to remove instead of comment
# sudo sed -i '/swap/d' /etc/fstab

echo "The swap partition line has been updated in /etc/fstab. A backup was saved as /etc/fstab.bak"




echo "please see token generated using the below comand on the control plane server"
echo "kubeadm token create --print-join-command"

echo "Look at README.md for the example https://github.com/Hawaiideveloper/k8-provisions/blob/main/README.md"