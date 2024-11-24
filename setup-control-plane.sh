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

# explicitly set the runtime endpoint for crictl
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps | grep kube-apiserver


# Description: Automate creation of crictl.yaml for runtime endpoint configuration
# Author: Hawaiideveloper
# Date: 2024-11-24
# Version: 1.0
# Usage: sudo ./setup-crictl-config.sh

# Define the default runtime endpoints for common container runtimes
CONTAINERD_ENDPOINT="unix:///run/containerd/containerd.sock"
CRI_O_ENDPOINT="unix:///run/crio/crio.sock"
CRI_DOCKERD_ENDPOINT="unix:///var/run/cri-dockerd.sock"

# Check if the runtime is containerd, cri-o, or cri-dockerd
if pgrep -x "containerd" > /dev/null; then
    RUNTIME_ENDPOINT=$CONTAINERD_ENDPOINT
    RUNTIME_NAME="containerd"
elif pgrep -x "crio" > /dev/null; then
    RUNTIME_ENDPOINT=$CRI_O_ENDPOINT
    RUNTIME_NAME="cri-o"
elif pgrep -x "dockerd" > /dev/null; then
    RUNTIME_ENDPOINT=$CRI_DOCKERD_ENDPOINT
    RUNTIME_NAME="cri-dockerd"
else
    echo "No supported container runtime detected. Please ensure containerd, cri-o, or cri-dockerd is installed and running."
    exit 1
fi

# Create or update the crictl.yaml configuration file
CONFIG_FILE="/etc/crictl.yaml"

echo "Setting up crictl.yaml for $RUNTIME_NAME runtime at $RUNTIME_ENDPOINT..."

sudo mkdir -p /etc
sudo tee $CONFIG_FILE > /dev/null <<EOF
runtime-endpoint: $RUNTIME_ENDPOINT
image-endpoint: $RUNTIME_ENDPOINT
EOF

# Set correct permissions
sudo chmod 644 $CONFIG_FILE

echo "Configuration completed. Runtime: $RUNTIME_NAME, Endpoint: $RUNTIME_ENDPOINT"
echo "You can verify with: crictl ps"












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


# Backup the original /etc/fstab file
sudo cp /etc/fstab /etc/fstab.bak

# Comment out the swap entry in /etc/fstab
sudo sed -i '/swap/s/^/#/' /etc/fstab

# Disable swap immediately for the current session
sudo swapoff -a

# Confirm changes
echo "Swap has been disabled and /etc/fstab updated."


echo "Kubernetes control plane setup complete."
echo "See the kubeadm join command above to add worker nodes."




# If problems arise uncomment commands below:


# Check if the control plane was ever successfully initialized:
# sudo kubeadm reset

# Reinitialize the Kubernetes control plane:
# This command will:

# Generate the missing manifests, including kube-apiserver.yaml.
# Start the control plane components (kube-apiserver, kube-controller-manager, kube-scheduler, etc.).
# sudo kubeadm init --apiserver-advertise-address=172.100.55.10 --pod-network-cidr=192.168.0.0/16


# If things go right you should see something like similar below:


# Your Kubernetes control-plane has initialized successfully!

# To start using your cluster, you need to run the following as a regular user:

#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/

# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 172.100.55.10:6443 --token bat9gc.ac5gu50icmp8bmts \
# 	--discovery-token-ca-cert-hash sha256:35a8c92dd45000b1a460f4398ef6eec4cca7f52624268eb6f6a8d79845aa9579 