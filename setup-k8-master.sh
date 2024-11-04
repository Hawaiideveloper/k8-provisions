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

