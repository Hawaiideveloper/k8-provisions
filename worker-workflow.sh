#!/bin/bash

# Worker Node Workflow for Kubernetes Cluster
# Ensures consistent IP addressing and proper connection to master
# Based on kubeadm version 1.31

# Exit immediately if a command fails
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
MASTER_IP="172.100.10.10"
MASTER_HOSTNAME="k8-master"
WORKER_IP_PREFIX="172.100.10"
WORKER_HOSTNAME_PREFIX="k8-worker"

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get worker node number from user
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kubernetes Worker Node Setup Workflow${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Master IP: ${MASTER_IP}${NC}"
echo -e "${YELLOW}Master Hostname: ${MASTER_HOSTNAME}${NC}"
echo ""

read -p "Enter worker node number (e.g., 1, 2, 3): " WORKER_NUMBER
WORKER_IP="${WORKER_IP_PREFIX}.$((10 + WORKER_NUMBER))"
WORKER_HOSTNAME="${WORKER_HOSTNAME_PREFIX}-0${WORKER_NUMBER}"

echo -e "${YELLOW}Worker IP: ${WORKER_IP}${NC}"
echo -e "${YELLOW}Worker Hostname: ${WORKER_HOSTNAME}${NC}"
echo ""

# Step 1: Disable cloud-init if present
print_status "Step 1: Checking and disabling cloud-init..."
if dpkg -l | grep -q cloud-init; then
    print_status "cloud-init detected, disabling..."
    sudo touch /etc/cloud/cloud-init.disabled
    sudo systemctl mask cloud-init
    sudo update-initramfs -u
    sudo rm -rf /var/lib/cloud/
    print_status "cloud-init disabled successfully"
else
    print_status "cloud-init not detected, skipping..."
fi

# Step 2: Configure network interface for consistent IP
print_status "Step 2: Configuring network interface..."
NETWORK_CONFIG="/etc/netplan/01-netcfg.yaml"

# Backup existing network config
if [ -f "$NETWORK_CONFIG" ]; then
    sudo cp "$NETWORK_CONFIG" "${NETWORK_CONFIG}.backup"
    print_status "Backup created at ${NETWORK_CONFIG}.backup"
fi

# Create new network configuration
print_status "Setting up static IP configuration..."
sudo tee "$NETWORK_CONFIG" > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:  # Adjust interface name if needed
      dhcp4: false
      addresses:
        - ${WORKER_IP}/24
      gateway4: 172.100.10.1
      nameservers:
          addresses: [172.100.55.2, 8.8.4.4]
          search: [albrightlabs.local]
EOF

# Apply network configuration
print_status "Applying network configuration..."
sudo netplan apply
print_status "Network configuration applied"

# Step 3: Set hostname
print_status "Step 3: Setting hostname..."
sudo hostnamectl set-hostname "$WORKER_HOSTNAME"
echo "$WORKER_IP $WORKER_HOSTNAME" | sudo tee -a /etc/hosts
echo "$MASTER_IP $MASTER_HOSTNAME" | sudo tee -a /etc/hosts

# Step 4: Fix DNS configuration
print_status "Step 4: Configuring DNS for kubelet compatibility..."
RESOLV_FILE="/etc/resolv.conf"

# Backup existing resolv.conf
if [ -f "$RESOLV_FILE" ]; then
    sudo cp "$RESOLV_FILE" "${RESOLV_FILE}.backup"
    print_status "DNS backup created at ${RESOLV_FILE}.backup"
fi

# Configure DNS
sudo tee "$RESOLV_FILE" > /dev/null <<EOF
nameserver 172.100.55.2
nameserver 8.8.4.4
search albrightlabs.local
EOF

sudo systemctl restart systemd-resolved
print_status "DNS configuration updated"

# Step 5: Disable swap
print_status "Step 5: Disabling swap..."
sudo swapoff -a
sudo sed -i '/\/swap.img/ s/^/#/' /etc/fstab
print_warning "If swap line still exists in /etc/fstab, please comment it out manually"
grep '/swap.img' /etc/fstab || print_status "No swap entries found in /etc/fstab"

# Step 6: Configure system parameters
print_status "Step 6: Configuring system parameters..."
sudo tee /etc/sysctl.d/k8s.conf > /dev/null <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
print_status "System parameters configured"

# Step 7: Remove conflicting packages
print_status "Step 7: Removing conflicting packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 2>/dev/null || true
done
print_status "Conflicting packages removed"

# Step 8: Install containerd
print_status "Step 8: Installing and configuring containerd..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Add Docker repository
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

# Configure containerd
containerd config default | \
sed 's/SystemdCgroup = false/SystemdCgroup = true/' | \
sed 's/sandbox_image = "registry.k8s.io\/pause:3.6"/sandbox_image = "registry.k8s.io\/pause:3.10"/' | \
sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd
print_status "Containerd installed and configured"

# Step 9: Install Kubernetes components
print_status "Step 9: Installing Kubernetes components..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes repository
sudo mkdir -p -m 755 /etc/apt/keyrings
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo apt-get update
K8S_VERSION="1.31.4-1.1"
sudo apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
print_status "Kubernetes components installed"

# Step 10: Test connectivity to master
print_status "Step 10: Testing connectivity to master node..."
if ping -c 3 $MASTER_IP > /dev/null 2>&1; then
    print_status "Successfully pinged master node"
else
    print_error "Cannot ping master node. Please check network connectivity."
    exit 1
fi

# Step 11: Get join command from user
print_status "Step 11: Ready to join cluster..."
print_warning "You need to get the join command from the master node."
print_warning "Run this command on the master node: sudo kubeadm token create --print-join-command"
echo ""
read -p "Enter the join command from the master node: " JOIN_COMMAND

# Step 12: Join the cluster
print_status "Step 12: Joining the cluster..."
eval $JOIN_COMMAND

# Step 13: Verify node joined successfully
print_status "Step 13: Verifying node joined successfully..."
sleep 10
if kubectl get nodes | grep -q "$WORKER_HOSTNAME"; then
    print_status "Worker node successfully joined the cluster!"
else
    print_warning "Node may still be joining. Check status on master node with: kubectl get nodes"
fi

# Final status
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Worker Node Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Worker IP: ${WORKER_IP}${NC}"
echo -e "${BLUE}Worker Hostname: ${WORKER_HOSTNAME}${NC}"
echo -e "${BLUE}Master IP: ${MASTER_IP}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. On the master node, label this worker: kubectl label nodes $WORKER_HOSTNAME node-role.kubernetes.io/worker-node=worker --overwrite"
echo "2. Verify node status: kubectl get nodes"
echo "3. Check if all pods are running: kubectl get pods --all-namespaces"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "kubectl get nodes"
echo "kubectl get pods --all-namespaces"
echo "kubectl describe node $WORKER_HOSTNAME"
echo "" 