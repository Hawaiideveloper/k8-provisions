#!/bin/bash

# Master Node Workflow for Kubernetes Cluster
# Ensures consistent IP addressing with 172.100.10.x/24 network
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
POD_NETWORK_CIDR="192.168.79.0/24"
K8S_VERSION="1.31.4-1.1"
K8S_VER="1.31.4"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kubernetes Master Node Setup Workflow${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Target IP: ${MASTER_IP}${NC}"
echo -e "${YELLOW}Hostname: ${MASTER_HOSTNAME}${NC}"
echo -e "${YELLOW}Pod Network: ${POD_NETWORK_CIDR}${NC}"
echo ""

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
        - ${MASTER_IP}/24
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
sudo hostnamectl set-hostname "$MASTER_HOSTNAME"
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
sudo apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
print_status "Kubernetes components installed"

# Step 10: Pre-pull required images
print_status "Step 10: Pre-pulling Kubernetes images..."
sudo kubeadm config images pull --kubernetes-version=$K8S_VER
print_status "Images pre-pulled successfully"

# Step 11: Initialize Kubernetes control plane
print_status "Step 11: Initializing Kubernetes control plane..."
print_warning "This step will initialize the control plane. Make sure you're ready to proceed."
read -p "Press Enter to continue with kubeadm init..."

sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version=$K8S_VER --apiserver-advertise-address=$MASTER_IP

# Step 12: Configure kubectl
print_status "Step 12: Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
print_status "kubectl configured"

# Step 13: Install Calico CNI
print_status "Step 13: Installing Calico CNI..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
print_status "Calico CNI installed"

# Step 14: Restart kubelet
print_status "Step 14: Restarting kubelet..."
sudo systemctl restart kubelet
print_status "kubelet restarted"

# Step 15: Display join command
print_status "Step 15: Generating join command for worker nodes..."
JOIN_COMMAND=$(sudo kubeadm token create --print-join-command)
print_status "Worker nodes can join using this command:"
echo -e "${YELLOW}$JOIN_COMMAND${NC}"

# Step 16: Display cluster status
print_status "Step 16: Checking cluster status..."
kubectl get nodes
kubectl get pods --all-namespaces

# Step 17: Label master node
print_status "Step 17: Labeling master node..."
kubectl label nodes $(hostname) node-role.kubernetes.io/control-plane=control-plane --overwrite
kubectl label nodes $(hostname) node-role.kubernetes.io/master=master --overwrite
print_status "Master node labeled"

# Final status
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Master Node Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Master IP: ${MASTER_IP}${NC}"
echo -e "${BLUE}Hostname: ${MASTER_HOSTNAME}${NC}"
echo -e "${BLUE}Pod Network: ${POD_NETWORK_CIDR}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run the worker-node.sh script on worker nodes"
echo "2. Use the join command above to add worker nodes"
echo "3. Label worker nodes with: kubectl label nodes <worker-hostname> node-role.kubernetes.io/worker-node=worker --overwrite"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "kubectl get nodes"
echo "kubectl get pods --all-namespaces"
echo "kubectl cluster-info"
echo "" 