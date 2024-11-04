# The hostnamectl command only allows a single argument for the hostname
sudo hostnamectl set-hostname k8s-control

# Need to setup host file for names of each node and master


# used to create a configuration file for loading kernel 
# modules necessary for container networking and overlay filesystems,
cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# loads the overlay kernel module into the running Linux kernel
# Purpose of the overlay Module
# The overlay module allows multiple filesystem layers to be overlaid on top of each other, which is useful in containerized environments 
# where multiple containers may share base filesystem images without duplicating the data.
sudo modprobe overlay


# essential for enabling certain network filtering
# enables network traffic on Linux bridges to be filtered using iptables
sudo modprobe br_netfilter

# creates a system configuration file to enable specific network settings
# Ensures that bridged network traffic 
#(traffic passing through Linux bridges) is processed by iptables
# Enables IPv4 packet forwarding, allowing 
# the system to forward packets between network interfaces
# Ensures that IPv6 traffic passing through 
# Linux bridges is processed by ip6tables

cat << EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables =1 
EOF

# Reloads all configuration files in /etc/sysctl.d/
sudo sysctl --system

# Update the system to get any updates and install containerd 
sudo apt-get update && sudo apt-get install -y containerd

# Create a containerd config file
sudo mkdir -p /etc/containerd

# generates a default configuration file for containerd 
# and saves it to /etc/containerd/config.toml
sudo containerd config default | sudo tee /etc/containerd/config.toml


# Restart containerd for changes to take effect:
sudo systemctl restart containerd

# Disable virtual memory (Consistency and Predictability)Kubernetes node agent) 
# will refuse to start if swap is enabled 
sudo swapoff -a

# apt-transport-https: Allows apt to communicate over HTTPS, 
# which is required when downloading packages from secur
sudo apt-get update && sudo apt-get install -y apt-transport-https curl

# Downloads and adds Google’s GPG key to your system’s list of trusted keys.
# Add signature file apt-key.gpg
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Adding the Kubernetes package repository for 
# Debian-based systems (such as Ubuntu)
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Take in the changes
sudo apt-get update

# Install kubeadm to version 1.27.0-00
sudo apt-get install -y kubelet=1.27.0-00 kubeadm=1.27.0-00 kubectl=1.27.0-00

# Locks version to 1.27
sudo apt-mark hold kubelet kubeadm kubectl




