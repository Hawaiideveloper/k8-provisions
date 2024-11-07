#!/bin/bash

# Description: Set up a Kubernetes control plane node and configure DNS
# Author: Hawaiideveloper
# Date: 2024-11-03
# Version: 1.2
# Usage: ./script_name.sh
# Notes: Automates Kubernetes initialization and DNS configuration.

# Detect the primary network adapter and hold is as ADAPTER
ADAPTER=$(ip route | grep default | awk '{print $5}')

if [ -z "$ADAPTER" ]; then
  echo "No network adapter detected. Please check your network configuration."
  exit 1
fi

echo "Detected network adapter: $ADAPTER"

# Initializes a Kubernetes control plane node with specific settings
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version v1.31.2

# Setup kubeconfig for the current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico for networking
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

# Generates a new token and displays the join command for worker nodes
kubeadm token create --print-join-command

# Configure DNS
cat <<EOF | sudo tee /etc/netplan/99-custom-dns.yaml
network:
  version: 2
  ethernets:
    $ADAPTER:
      dhcp4: no
      addresses:
        - 172.100.55.10/24  # Replace with your static IP
      gateway4: 172.100.55.1
      nameservers:
        addresses:
          - 172.100.55.2
          - 192.168.1.1
          - 8.8.8.8
EOF

sudo netplan apply

echo "Kubernetes control plane setup complete."
echo "See the kubeadm join command above to add worker nodes."
