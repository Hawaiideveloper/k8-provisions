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