#!/bin/bash

# Exit immediately if a command fails
set -e

# Ensure required tools are installed
echo "Installing required tools..."
sudo apt-get update -y
sudo apt-get install -y curl apt-transport-https ca-certificates gnupg software-properties-common qemu qemu-kvm
sudo apt-get install -y containerd

# Make containerd or update containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml


# Remove any incorrect Kubernetes repository configurations
echo "Removing incorrect Kubernetes repository configuration..."
sudo rm -f /etc/apt/sources.list.d/kubernetes.list

# Set the sandbox image to the correct Kubernetes image with backup:
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.bak
sudo sed -i 's|sandbox_image = .*|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml

# Set crictl as the default endpoints
sudo sed -i '1i runtime-endpoint: unix:///run/containerd/containerd.sock\nimage-endpoint: unix:///run/containerd/containerd.sock\ntimeout: 10\ndebug: false' /etc/crictl.yaml

# STart the containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Verify the containerd version and is running
sudo systemctl status containerd


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


# Enable IP forwarding
echo "Temporarily Enable IP Forwarding:"
sudo sysctl -w net.ipv4.ip_forward=1

echo "Persist IP Forwarding Across Reboots:"
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf

echo "Reload the configuration:"
sudo sysctl --system

echo "Verify the setting .... it should equal 1"
cat /proc/sys/net/ipv4/ip_forward


# Pre=pull required images
K8S_VER="1.31.4"
sudo kubeadm config images pull --kubernetes-version=$K8S_VERS


# Initialize Kubernetes control plane
echo "Initializing Kubernetes control plane..."
POD_NETWORK_CIDR="192.168.79.0/24"
K8S_VER="1.31.4"
sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version=$K8S_VER
echo "if this fails you can try sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version=$K8S_VERSION --ignore-preflight-errors=all"


# Set up kubeconfig for the current user
echo "Setting up kubeconfig..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# You can now join worker nodes using a command like this
Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.100.55.20:6443 --token tkkiyb.76u6s7gwxqgm602h \
	--discovery-token-ca-cert-hash sha256:fcf0da56bf564a19b7e4bf02fda824c85b5d301cb7c21e0b90c3eca02214a448 


#################################### YOu need to Reboot cause nothing really will work on the next steps #################
sudo reboot

# Fixing the kube-system not seeing the needed files
sudo kubeadm init phase kubelet-start









# Calico is where we left off